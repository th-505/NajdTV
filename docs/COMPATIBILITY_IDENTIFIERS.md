# NajdTV compatibility identifiers

The product and every active user-facing label are **NajdTV / نجد**. The
following legacy strings remain intentionally because changing them would break
installed applications, stored user data, database history, or live cloud
connections:

- Dart package name `mitv`, application IDs under `com.mitv`, and build-time
  variables beginning `MITV_`.
- LocalStorage/SharedPreferences keys and download-resume filenames beginning
  `mitv` or `matv`; these are migration inputs, not displayed branding.
- Applied Supabase tables/functions beginning `mitv_` or `matv_`.
- Live resource names and endpoints such as `matv.onrender.com`,
  `matv-edge-resolver`, and existing Worker service binding names.
- Historical fixture inputs whose old wording is required to test migration or
  backward compatibility.

New visible copy, logs, diagnostics, user agents, icons, and generated artifact
names use NajdTV. Compatibility identifiers must not be renamed without an
explicit data/application migration and a verified rollback path.
