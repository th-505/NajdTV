Six failing fixture suites — decisions

Reference baseline: 7317d9c86e85770cf4fff6f9da5b69fd3352f9c6.
All six failures predate these changes. No previously green assertion was removed.

| Suite | Finding | Correction |
|---|---|---|
| 3isk | Legacy expected canonical origin ww4.3ick.club; current code config selects 3iskk.xyz. Live root returned HTML at 3iskk.xyz; details redirect remains unverified. | Expect configured canonical rewrite for legacy/relative references; retain absolute fixture-domain content assertions and unsafe-URL tests. No new domain adopted. |
| Arabseed | Live form at m.myseed.tv has action /find/ and input name=word. | Correct outdated find parameter and canonical work URL expectations. Keep original poster provenance. |
| CimaNow | Current adapter canonicalizes to cimanow.info. Its redirect destination identifies as MySeed and is not approved as CimaNow. | Correct stale cimanow.me rewrite expectations to the existing configured origin, without asserting live availability or accepting MySeed. |
| Laroza | Relative references use configured laroza.buzz; existing absolute legacy references retain their origin. Both differ from old blanket larooza.beer expectations. | Test relative/absolute behavior separately; no change to source allowlists or claim of live recovery. |
| QFilm | Live HTML form and JSON-LD declare /search.php?keywords=... | Correct stale s parameter expectation. |
| MyCima | Direct links in HTML fixtures have no media-probe evidence. | Expect verified=false for extracted fixture servers; test unresolved embed with an explicit local HTTP mock, never live network. |

`npm run test:provider-fixtures` runs these six suites with an offline fetch
guard that fails on accidental live requests, including swallowed failures.
It is included in `npm run check`, so standard CI executes the corrected suites.
These are deterministic contract checks, not live playback certification.

Integration with newer main: Akwam's previously MP4-only assertion excluded the
HLS literal already present in DOWNET_BRIDGE_HTML. Main now correctly collects
all alternatives. The test asserts all six exact observed paths, each matching
its MP4/HLS extension, while retaining server IDs, headers and original quality
ordering. This seventh suite also runs under the offline CI guard.

The Content runtime pull-request workflow also runs this suite explicitly after
npm ci, so audited fixtures do not depend on manually dispatched feature gates.
