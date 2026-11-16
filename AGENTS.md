# Najd TV repository instructions

For product UI/branding work read `.agents/skills/najd-brand/SKILL.md`.
For provider/discovery/harvesting or Gemini maintenance work read `.agents/skills/najd-scraper-maintenance/SKILL.md`.
The current requirements and acceptance checklist are in `docs/najd/IMPLEMENTATION_1.1.5.md`.
Never delete a historical feature because import fan-in is zero; inspect entry points, conditional imports, native bridges and tests first. Keep private font inputs, credentials and user exports outside Git. Preserve installed-user compatibility IDs and migrations.


## User build and release approval policy (2026-11-16)

Before starting ANY application/package build or publication, tell the user exactly what will be built and wait for explicit approval. Earlier broad authorization to continue development does not authorize a new build. This includes CI artifact builds, Flutter release builds, Docker/Render rebuilds, workflow dispatches and reruns. Never push to `build/mitv-*`, merge/push to `main`, open a build-triggering PR, or change production code in a way that auto-deploys before obtaining that approval. Do not interpret silence or elapsed time as consent.

Current batch: the user explicitly authorized server updates and six application targets for **5.2.0**, but final package builds/publication must wait until all requested client acceptance tasks pass. Push reviewable work to an ordinary review branch while work remains; do not trigger release builds indirectly through `build/mitv-*` pushes or a production auto-deploy. Read `docs/najd/PENDING_ACCOUNT_AND_SETTINGS.md` for decisions, implemented changes, actual test evidence and outstanding work.

## Latest explicit authorization (2026-11-16)
The user now authorizes the requested server updates and six application targets after all client acceptance tasks pass. Do not start final release builds with unfinished tasks. Release version confirmed: 5.2.0.
