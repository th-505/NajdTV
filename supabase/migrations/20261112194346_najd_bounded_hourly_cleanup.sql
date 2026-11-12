create or replace function public.najd_hourly_refresh() returns jsonb
language plpgsql set search_path='' as $$
declare count_due integer; removed integer;
begin
 if not pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtextextended('najd-favorite-hourly',0)) then
  return pg_catalog.jsonb_build_object('state','already_running');
 end if;
 count_due:=mitv_private.najd_queue_current_favorites(true);
 update public.matv_discovery_jobs set status='queued',worker_id=null,lease_until=null,refresh_after=now()
 where job_key in(select job_key from public.matv_discovery_jobs where status='running' and lease_until<now() and attempts<5 limit 500 for update skip locked);
 update public.matv_discovery_jobs set status='failed',worker_id=null,lease_until=null,error_code='LEASE_EXHAUSTED'
 where job_key in(select job_key from public.matv_discovery_jobs where status='running' and lease_until<now() and attempts>=5 limit 500 for update skip locked);
 delete from public.matv_discovery_jobs where job_key in(
  select j.job_key from public.matv_discovery_jobs j
  where j.last_activity_at<now()-interval '7 days' and j.status<>'running'
  and not exists(select 1 from public.najd_work_catalog c where c.ref=j.content_ref and c.expires_at>now())
  limit 500 for update of j skip locked);
 get diagnostics removed=row_count;
 update public.najd_episode_cache set state='pending',media='[]',media_expires_at=null
 where ctid in(select ctid from public.najd_episode_cache where media_expires_at<=now() limit 500 for update skip locked);
 delete from public.najd_work_catalog where ref in(
  select c.ref from public.najd_work_catalog c where c.expires_at<now()
  and not exists(select 1 from public.mitv_library l where l.kind='favorite' and not l.deleted and mitv_private.najd_favorite_work_reference(l.item_key,l.metadata)=c.ref)
  limit 50 for update of c skip locked);
 delete from public.najd_harvest_events where ctid in(
  select ctid from public.najd_harvest_events where created_at<now()-interval '30 days' limit 1000 for update skip locked);
 perform mitv_private.najd_wake();
 return pg_catalog.jsonb_build_object('due_works',count_due,'removed_jobs',removed,'cleanup_batch_limit',500);
end $$;
revoke all on function public.najd_hourly_refresh() from public,anon,authenticated;
grant execute on function public.najd_hourly_refresh() to service_role;
