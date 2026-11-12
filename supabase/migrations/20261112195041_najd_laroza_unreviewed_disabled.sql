-- Redirect chains did not reach a verifiable catalog. No new domains are trusted.
update public.najd_provider_config set enabled=false,revision=revision+1,updated_at=now() where provider='laroza' and enabled;
update public.najd_beta_provider_config set enabled=false,revision=revision+1,updated_at=now() where provider='laroza' and enabled;
