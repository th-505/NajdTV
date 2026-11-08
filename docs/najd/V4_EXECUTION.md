# v4.0.1 execution record

## Database — applied, not a pending migration
`20261107230635_najd_v4_schema_performance.sql` adds two FK indexes, optimizes eight legacy owner policies with `(select auth.uid())`, and documents ownership/catalog responsibilities without renaming or deleting data. Verified two new indexes and eight optimized policies; rollback-only authenticated owner isolation checks passed. The performance advisor then reported unused-index notices only; these were retained. See V4_DATABASE_AND_RECOVERY.md for the table map and limitations.

## Sources and application
Both independent source families retain 25 registered modules, 23 non-mirror search providers and two explicit mirrors. Existing 3isk identity was updated rather than duplicated. Observed fixtures cover real 3isk search/seasons, 23 matching Moviz Time anime seasons and ownership-safe episode handles. WitAnime remains blocked from this environment; local HTML success elsewhere does not certify CDN playback or production accessibility.

Player, carousel, catalog filters, actor sorting, TV focus/Back, smaller cards and poster preview changes are described in RELEASE_4.0.1.md. The Web player remains available in the website and uses compatible direct sources; no paid conversion service or advertisement SDK was introduced. Browser codec and CORS limits cannot be removed by UI changes.

## Local verification
- 261 Node tests passed.
- `npm run check` and continuation checks passed, including 154 offline source fixtures with zero network attempts.
- TV focused navigation/layout/preview/Back checks: 10 passed, one desktop-only skip.
- Flutter analyze: no issues. Full Flutter suite and final browser media/PiP smoke are release gates.
- Earlier actual Chromium fixture playback rendered MP4 and the shared UI; this is distinct from physical iPhone/TV PiP certification.

## Distribution gate
Publish only after all six target artifacts and the artifact verifier pass at the reviewed source commit. Android uses the persistent release key; unsigned IPA requires appropriate sideload signing, and macOS is ad-hoc without notarization. Check deployed Web/API version separately after merging and promotion. No credentials are recorded in this document.
