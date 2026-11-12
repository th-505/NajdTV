-- MATV 2026-10 unified content/discovery lifecycle, backward-compatible.
-- Keep existing favorites, watch history, catalog and provider cache intact.
alter table public.mitv_favorites add column if not exists last_requested_at timestamptz;
alter table public.mitv_favorites add column if not exists last_watched_at timestamptz;
alter table public.mitv_watch_history add column if not exists last_played_at timestamptz;
alter table public.mitv_watch_history add column if not exists completed_at timestamptz;
create index if not exists mitv_favorites_content_ref_idx on public.mitv_favorites(content_ref);
create index if not exists mitv_watch_history_recent_idx on public.mitv_watch_history(content_ref,updated_at desc);
create index if not exists matv_provider_cache_expiry_idx on public.matv_provider_cache(expires_at);
create table if not exists public.matv_discovery_jobs (
  job_key text primary key check (length(job_key) between 1 and 180),
  content_ref text not null check (content_ref ~ '^tmdb:(movie|tv):[0-9]+$'),
  title text not null check (length(title) between 2 and 250),
  original_title text,
  release_year integer check (release_year between 1880 and 2200),
  season_number integer not null default 0 check (season_number between 0 and 100),
  episode_number integer not null default 0 check (episode_number between 0 and 100000),
  status text not null default 'queued' check (status in ('queued','running','ready','failed')),
  priority smallint not null default 0 check (priority between 0 and 10),
  attempts smallint not null default 0 check (attempts between 0 and 5),
  requested_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  lease_until timestamptz,
  refresh_after timestamptz,
  last_activity_at timestamptz not null default now(),
  error_code text,
  updated_at timestamptz not null default now()
);
create index if not exists matv_discovery_jobs_schedule_idx on public.matv_discovery_jobs(status,priority desc,requested_at);
create index if not exists matv_discovery_jobs_refresh_idx on public.matv_discovery_jobs(refresh_after);
create table if not exists public.matv_content_demand (
  content_ref text primary key check (content_ref ~ '^tmdb:(movie|tv):[0-9]+$'),
  favorite_count integer not null default 0 check (favorite_count >= 0),
  weekly_watch_count integer not null default 0 check (weekly_watch_count >= 0),
  last_favorited_at timestamptz,
  last_watched_at timestamptz,
  refresh_after timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists matv_content_demand_refresh_idx on public.matv_content_demand(refresh_after);
alter table public.matv_discovery_jobs enable row level security;
alter table public.matv_content_demand enable row level security;
revoke all on public.matv_discovery_jobs from anon,authenticated;
revoke all on public.matv_content_demand from anon,authenticated;
grant all on public.matv_discovery_jobs to service_role;
grant all on public.matv_content_demand to service_role;
