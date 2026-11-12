-- Missing config rows previously fell back to enabled provider defaults.
insert into public.najd_provider_config(provider,enabled) values('laroza',false) on conflict(provider) do update set enabled=false,revision=najd_provider_config.revision+1,updated_at=now() where najd_provider_config.enabled;
insert into public.najd_beta_provider_config(provider,enabled) values('laroza',false) on conflict(provider) do update set enabled=false,revision=najd_beta_provider_config.revision+1,updated_at=now() where najd_beta_provider_config.enabled;
