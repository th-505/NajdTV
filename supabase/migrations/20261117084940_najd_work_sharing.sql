begin;
set local lock_timeout='3s';
-- Shares contain catalogue metadata only. They never delegate private library writes.
create table public.najd_work_shares (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 payload jsonb not null check(jsonb_typeof(payload)='object' and octet_length(payload::text)<=16384 and mitv_private.metadata_is_safe(payload)),
 state text not null default 'pending' check(state in('pending','accepted','declined')),
 created_at timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '7 days',
 responded_at timestamptz,
 check(sender_id<>recipient_id)
);
create index najd_work_shares_recipient on public.najd_work_shares(recipient_id,state,created_at desc);
create index najd_work_shares_sender on public.najd_work_shares(sender_id,created_at desc);
alter table public.najd_work_shares enable row level security;
revoke all on public.najd_work_shares from public,anon,authenticated;
grant select on public.najd_work_shares to authenticated;
grant all on public.najd_work_shares to service_role;
create policy najd_work_shares_participants on public.najd_work_shares for select to authenticated
 using(((select auth.uid())=sender_id or (select auth.uid())=recipient_id) and (select (auth.jwt()->>'is_anonymous')::boolean) is false);

create function mitv_private.najd_share_work(p_recipient uuid,p_payload jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); shared_id uuid;
begin
 if uid is null or not exists(select 1 from auth.users where id=uid and not is_anonymous and email_confirmed_at is not null) then raise exception 'REGISTERED_ACCOUNT_REQUIRED'; end if;
 if p_recipient is null or p_recipient=uid or not exists(select 1 from auth.users where id=p_recipient and not is_anonymous and email_confirmed_at is not null) then raise exception 'INVALID_SHARE_RECIPIENT'; end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>16384 or not mitv_private.metadata_is_safe(p_payload)
 or coalesce(length(p_payload->>'content_ref'),0) not between 1 and 1536
 or p_payload->>'content_ref' ~ '[[:cntrl:]]|://'
 or coalesce(length(p_payload->>'title'),0) not between 1 and 250
 or coalesce(p_payload->>'position_ms','') !~ '^[0-9]{1,9}$'
 or (p_payload->>'position_ms')::bigint>604800000 then raise exception 'INVALID_SHARE_PAYLOAD'; end if;
 perform pg_advisory_xact_lock(hashtextextended(least(uid::text,p_recipient::text),520));
 perform pg_advisory_xact_lock(hashtextextended(greatest(uid::text,p_recipient::text),520));
 if (select count(*) from public.najd_work_shares where sender_id=uid and created_at>now()-interval '1 hour')>=20 then raise exception 'SHARE_RATE_LIMITED'; end if;
 if (select count(*) from public.najd_work_shares where recipient_id=p_recipient and state='pending' and expires_at>now())>=50 then raise exception 'SHARE_INBOX_FULL'; end if;
 insert into public.najd_work_shares(sender_id,recipient_id,payload) values(uid,p_recipient,p_payload) returning id into shared_id;
 return shared_id;
end $$;
create function mitv_private.najd_share_respond(p_id uuid,p_accept boolean) returns boolean
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or p_accept is null then raise exception 'AUTH_REQUIRED'; end if;
 update public.najd_work_shares set state=case when p_accept then 'accepted' else 'declined' end,responded_at=clock_timestamp()
 where id=p_id and recipient_id=auth.uid() and state='pending' and expires_at>clock_timestamp();
 if not found then raise exception 'SHARE_NOT_PENDING'; end if;
 return true;
end $$;
-- Exposed RPCs are invokers; privileged validation lives outside the API schema.
create function public.najd_share_work(p_recipient uuid,p_payload jsonb) returns uuid
language sql security invoker set search_path='' as $$select mitv_private.najd_share_work(p_recipient,p_payload)$$;
create function public.najd_share_respond(p_id uuid,p_accept boolean) returns boolean
language sql security invoker set search_path='' as $$select mitv_private.najd_share_respond(p_id,p_accept)$$;
revoke all on function mitv_private.najd_share_work(uuid,jsonb),mitv_private.najd_share_respond(uuid,boolean) from public,anon;
grant execute on function mitv_private.najd_share_work(uuid,jsonb),mitv_private.najd_share_respond(uuid,boolean) to authenticated;
-- Explicit RPCs keep callers independent of Data API table exposure configuration.
create function public.najd_share_inbox() returns setof public.najd_work_shares
language sql stable security invoker set search_path='' as $$
 select * from public.najd_work_shares where recipient_id=auth.uid() and state='pending' and expires_at>now() order by created_at limit 20
$$;
create function public.najd_shared_works() returns setof public.najd_work_shares
language sql stable security invoker set search_path='' as $$
 select * from public.najd_work_shares where (sender_id=auth.uid() or recipient_id=auth.uid()) and state='accepted' order by created_at desc limit 250
$$;
revoke all on function public.najd_share_work(uuid,jsonb),public.najd_share_respond(uuid,boolean),public.najd_share_inbox(),public.najd_shared_works() from public,anon;
grant execute on function public.najd_share_work(uuid,jsonb),public.najd_share_respond(uuid,boolean),public.najd_share_inbox(),public.najd_shared_works() to authenticated;
do $$begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  alter publication supabase_realtime add table public.najd_work_shares;
 end if;
end $$;
commit;
