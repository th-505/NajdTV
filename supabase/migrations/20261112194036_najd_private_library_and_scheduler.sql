-- Private rows belong to the authenticated user even when handoff is linked.
create or replace function public.najd_touch_account() returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); owner uuid;
begin
 if uid is null or not exists(select 1 from auth.users where id=uid) then raise exception 'NAJD_AUTH_REQUIRED'; end if;
 insert into mitv_private.najd_account_activity(user_id) values(uid) on conflict(user_id) do update set last_seen=now();
 insert into public.najd_profiles(user_id) values(uid) on conflict do nothing;
 owner:=uid;
 return jsonb_build_object('owner_scope',owner,'grant_id',(select grant_id from mitv_private.najd_library_grants where member_id=uid and(expires_at is null or expires_at>now())),'expires_at',(select expires_at from mitv_private.najd_library_grants where member_id=uid and(expires_at is null or expires_at>now())));
end $$;

create or replace function public.najd_pull_library(p_after bigint default 0,p_limit integer default 250) returns setof jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); owner uuid;
begin
 if uid is null or not exists(select 1 from auth.users where id=uid) then raise exception 'NAJD_AUTH_REQUIRED'; end if;
 owner:=uid;
 return query select to_jsonb(l)||jsonb_build_object('user_id',uid) from public.mitv_library l where l.user_id=owner and l.sync_revision>greatest(0,p_after) order by l.sync_revision limit least(greatest(p_limit,1),250);
end $$;

create or replace function public.najd_upsert_library(rows jsonb) returns setof jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); owner uuid; entry jsonb; stamp timestamptz;
begin
 if uid is null or not exists(select 1 from auth.users where id=uid) then raise exception 'NAJD_AUTH_REQUIRED'; end if;
 owner:=uid;
 if rows is null or jsonb_typeof(rows)<>'array' or jsonb_array_length(rows)>32 then raise exception 'MITV_LIBRARY_BATCH_LIMIT'; end if;
 for entry in select value from jsonb_array_elements(rows) loop
  if entry ? 'user_id' and (entry->>'user_id')::uuid<>uid then raise exception 'MITV_LIBRARY_OWNER_REQUIRED'; end if;
  stamp:=least(coalesce((entry->>'updated_at')::timestamptz,clock_timestamp()),clock_timestamp()+interval '5 minutes');
  insert into public.mitv_library as l(user_id,kind,item_key,metadata,updated_at,deleted) values(owner,entry->>'kind',entry->>'item_key',coalesce(entry->'metadata','{}'),stamp,coalesce((entry->>'deleted')::boolean,false))
  on conflict(user_id,kind,item_key) do update set metadata=excluded.metadata,updated_at=excluded.updated_at,deleted=excluded.deleted where excluded.updated_at>l.updated_at;
 end loop;
 return query select to_jsonb(l)||jsonb_build_object('user_id',uid) from public.mitv_library l where l.user_id=owner and exists(select 1 from jsonb_array_elements(rows) e where e->>'kind'=l.kind and e->>'item_key'=l.item_key);
end $$;

-- Point lookup keeps a linked TV's resume independent of full-library pagination.
-- The authenticated member's active grant determines the owner; no owner ID is accepted.
create or replace function public.najd_history_checkpoint(p_item_key text)
returns setof jsonb language sql stable security definer set search_path='' as $$
 select to_jsonb(l)||jsonb_build_object('user_id',auth.uid())
 from public.mitv_library l
 where auth.uid() is not null
  and exists(select 1 from auth.users u where u.id=auth.uid())
  and octet_length(p_item_key) between 1 and 1536
  and l.user_id=auth.uid()
  and l.kind='history' and l.item_key=p_item_key
 limit 1;
$$;
revoke all on function public.najd_history_checkpoint(text) from public,anon;
grant execute on function public.najd_history_checkpoint(text) to authenticated,service_role;


create or replace function public.najd_refresh_favorite(p_ref text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare owner_id uuid := auth.uid(); r text; slot mitv_private.najd_refresh_cooldowns; delay_seconds integer; favorite_row public.mitv_library; source_reference text; queued boolean;
begin
 r := public.najd_work_reference(p_ref);
 if owner_id is null or r is null then raise exception 'AUTH_OR_REFERENCE_INVALID'; end if;
 select * into favorite_row from public.mitv_library
 where user_id=owner_id and kind='favorite' and not deleted
 and (item_key=p_ref or mitv_private.najd_favorite_work_reference(item_key,metadata)=r)
 order by case when item_key=p_ref then 0 else 1 end limit 1;
 if not found then raise exception 'FAVORITE_NOT_OWNED'; end if;
 insert into mitv_private.najd_refresh_cooldowns(user_id,work_ref) values(owner_id,r) on conflict do nothing;
 select * into slot from mitv_private.najd_refresh_cooldowns where user_id=owner_id and work_ref=r for update;
 if slot.next_allowed_at>clock_timestamp() then return pg_catalog.jsonb_build_object('queued',false,'retry_after',ceil(extract(epoch from(slot.next_allowed_at-clock_timestamp())))::integer); end if;
 delay_seconds := least(60,(case when slot.requested_at<now()-interval '10 minutes' then 1 else slot.tier+1 end)*10);
 update mitv_private.najd_refresh_cooldowns set tier=delay_seconds/10,requested_at=clock_timestamp(),next_allowed_at=clock_timestamp()+make_interval(secs=>delay_seconds) where user_id=owner_id and work_ref=r;
 source_reference := mitv_private.najd_favorite_source_reference(r,favorite_row.item_key,favorite_row.metadata);
 queued := mitv_private.najd_queue_favorite_work(r,source_reference,coalesce(nullif(favorite_row.metadata ->> 'title',''),'تحديث المفضلة'),10,true);
 perform mitv_private.najd_wake();
 return pg_catalog.jsonb_build_object('queued',queued,'retry_after',delay_seconds,'work_ref',r);
end $$;

-- The linked account group authorizes handoff only. It never owns private state.
-- Existing rows stay untouched: previously overwritten checkpoints cannot be inferred.
create or replace function mitv_private.najd_wake() returns void
language plpgsql security definer set search_path='' as $$
begin
 update mitv_private.najd_wake_clock set last_wake=clock_timestamp()
 where id and last_wake<clock_timestamp()-interval '15 seconds';
 if found then
  perform net.http_get(url:='https://najdtv.onrender.com/api/v1/harvest/wake',timeout_milliseconds:=10000);
 end if;
end $$;
revoke all on function mitv_private.najd_wake() from public,anon,authenticated;
-- Online index was built separately before this transactional migration.
-- IF NOT EXISTS also supports a fresh database without a concurrent build.
create index if not exists najd_queue_discovery_order on public.matv_discovery_jobs
(stage,priority desc,(coalesce(finished_at,'-infinity'::timestamptz)),requested_at)
where attempts<5 and stage<>'episode';
