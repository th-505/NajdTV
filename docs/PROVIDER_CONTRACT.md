Unified provider contract (additive migration)

All families use `shared/provider-contract.js`: legacy providers, registered Najd
scrapers, Beta/Browser wrappers, and public Node/Edge JSON responses. Existing
`status`, `number`, `num`, `season`, pagination and opaque reference aliases remain
for installed clients. They must not be used to invent canonical identity.

Work/item fields: `source`, `ref` (null if absent), `title`, `edition` (unknown when
not observed), `partial`, `next_cursor` (null when exhausted). Editions retain
their source vocabulary and source reference; dubbed/subtitled entries never
merge solely by title. Episode fields add `episode_id`, `episode_number`,
`season_number`, `watch_available`. Unknown numbers are null, never array indices.
Legacy default `season` is not promoted to canonical `season_number`.

Envelope `state`: ready, empty, queued, running, partial, unavailable. Preserve
queued/running from asynchronous jobs and HTTP 202. An unavailable response must
not become a successful empty array. `error_code` is the UI-facing code:
EMPTY_RESULT only after successful parsing of an actual result/empty-result area;
ACCESS_BLOCKED for 403/challenge; TIMEOUT for an elapsed deadline;
STRUCTURE_CHANGED for malformed JSON or missing expected markup. Preserve legacy
error `code` in diagnostics during migration. Other transport/config/security
errors remain distinct and are never relabelled EMPTY_RESULT.

Offsets resume the SAME upstream page. Laroza category/search use `page` plus
`offset`; details use `ref` plus `offset`. Limits are 60 catalog rows and 200
episode rows. At the boundary return partial=true and next_offset/next_cursor;
the final continuation may be empty. Upstream pagination remains independent.
Harvest continues to expose 100-row episode batches with `episode_pagination`
and `next_offset`; this contract does not change its queue or retention policy.

Migration order: source normalizers/wrappers -> modern API envelopes -> legacy
callers. Legacy array-only endpoints retain arrays; metadata stays in `_meta`
internally, modern envelopes carry explicit state. Consumers must use envelopes
for reliable error/partial-state display, never infer availability from length.

Security: no arbitrary URL cursors, no automatic domain adoption, no eval,
guarded HTTPS/DNS/redirect/body bounds on every upstream hop. JSON is validated
by parsing plus positive schema; Content-Type alone does not establish validity.
