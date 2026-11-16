-- Register explicit replacement identifiers without changing user rows or old references.
insert into public.najd_provider_registry(provider) values
  ('animezid'), ('movizland'), ('egybest'), ('live')
on conflict(provider) do nothing;
