# Current repository inventory

Regenerate with `python3 scripts/repository_inventory.py`. This inventories the files that remain; deletion evidence is delivered separately, not retained as an archive.

| Required file/group | Actual consumer |
|---|---|
| `app/source-manifest.json` | Negative legacy-build fixture read by scripts/platform_parity_test.py |
| `docs/legacy/index.html.source` | Browser and platform tests read this source |
| `library_backup_*` | Live Flutter import/export feature, native/web conditional implementations and tests |
| `docs/providers.json` | Generated current provider inventory checked by continuation CI |
| `docs/najd/RELEASE_4.0.2.md` | Current release notes read by dynamic release workflows |
| `supabase/migrations/` | Applied schema history; preserve all migrations |

Registered Najd and Beta providers remain independent. Do not delete an implementation solely because it has an identical hash or no ordinary import: inspect registry loading, native conditional imports and tests.

Current scan: 1258 files; 109 provider-family code/config files; 30 Markdown files. Full references, duplicate groups and backup-name matches are in `repository-inventory.json`.

The only repository skills retained are the Najd branding and guarded scraper maintenance contracts invoked by AGENTS.md. Shared website/internal-web build assets and their licenses remain where current entrypoints need them.
