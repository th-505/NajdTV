-- Optional observed episode metadata; keeps existing owners, source IDs and media caches.
set local lock_timeout = '2s';
alter table public.najd_episode_cache
 add column if not exists poster text check (poster is null or length(poster)<=4096),
 add column if not exists duration_seconds integer check (duration_seconds is null or duration_seconds between 1 and 604800),
 add column if not exists server_scan jsonb check (server_scan is null or pg_column_size(server_scan)<=32768);
create or replace function public.najd_upsert_episodes(p_rows jsonb) returns integer
language plpgsql security invoker set search_path='' as $$
declare n integer;
begin
 if jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows)>200 or pg_column_size(p_rows)>1048576 then raise exception 'INVALID_EPISODE_BATCH'; end if;
 insert into public.najd_episode_cache(work_ref,provider,source_ref,season,episode,title,indexed_at,poster,duration_seconds)
 select r.work_ref,r.provider,r.source_ref,r.season,r.episode,left(r.title,500),now(),nullif(r.poster,''),r.duration_seconds
 from jsonb_to_recordset(p_rows) as r(work_ref text,provider text,source_ref text,season integer,episode integer,title text,poster text,duration_seconds integer)
 on conflict(work_ref,provider,source_ref) do update set season=excluded.season,episode=excluded.episode,title=excluded.title,indexed_at=now(),updated_at=now(),
 poster=coalesce(excluded.poster,najd_episode_cache.poster),duration_seconds=coalesce(excluded.duration_seconds,najd_episode_cache.duration_seconds);
 get diagnostics n=row_count;return n;
end $$;
revoke all on function public.najd_upsert_episodes(jsonb) from public,anon,authenticated;
grant execute on function public.najd_upsert_episodes(jsonb) to service_role;
