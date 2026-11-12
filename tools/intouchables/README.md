# Isolated Intouchables resolver (deployment draft)

Start: `npm ci --omit=dev && node tools/intouchables/server.mjs` (use separate build/start commands on Render).

- `/health`: process health plus last source-check state.
- `/api/intouchables`: verified MP4 links, required source headers and inferred expiry.
- `/play`: redirects to the 480p stream. It does not relay video or attach headers on behalf of the client; use the API headers in a compatible player if needed.
- Refresh is on demand, at most hourly and before the inferred URL expiry. There is no background keepalive or automatic notification.
- Links are held in process memory and never committed. Restart triggers fresh extraction on the next request.
- The expiry timestamp is inferred from the source's URL path. Early revocation remains possible.
- Run as a separate Render service. Do not change either existing NajdTV service or its environment variables.

Pending: select a Render workspace; deploy from an isolated branch; verify extraction from Render's IP and playback outside Render. Local playback does not certify Render extraction or physical devices.
