-- Verified 2026-11-17: old primary redirects by HTTPS to the same branded site.
-- Both independent adapters returned 36 public catalogue entries from /home03.
-- Preserve unrelated selectors and any explicit disabled state.
begin;
insert into public.najd_provider_config(provider,config)
 values('brstej','{"primary_domain":"https://brstej1.site"}'::jsonb)
 on conflict(provider) do update set config=jsonb_set(najd_provider_config.config,'{primary_domain}','"https://brstej1.site"'::jsonb),revision=najd_provider_config.revision+1,updated_at=now()
 where najd_provider_config.config->>'primary_domain' is distinct from 'https://brstej1.site';
insert into public.najd_beta_provider_config(provider,config)
 values('brstej','{"primary_domain":"https://brstej1.site"}'::jsonb)
 on conflict(provider) do update set config=jsonb_set(najd_beta_provider_config.config,'{primary_domain}','"https://brstej1.site"'::jsonb),revision=najd_beta_provider_config.revision+1,updated_at=now()
 where najd_beta_provider_config.config->>'primary_domain' is distinct from 'https://brstej1.site';
commit;
