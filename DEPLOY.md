# Deploying the server (Render)

This document explains the minimal steps to deploy the server portion of this repo to Render and how to verify the Brevo email integration.

## Environment variables (Render service)

Most important (production): prefer the Brevo HTTP API key so outbound SMTP ports are not required.

- `BREVO_API_KEY` — Brevo HTTP (SMTP) API key (recommended for cloud hosts). If set, the server will use Brevo's HTTP API to send email.
- `BREVO_SENDER_EMAIL` — Verified sender email in Brevo (used by HTTP API and SMTP fallback).

Optional / SMTP fallback (only needed if you want SMTP fallback):
- `BREVO_SMTP_HOST` — smtp-relay.brevo.com (default)
- `BREVO_SMTP_PORT` — 587 (default)
- `BREVO_SMTP_USER` — Brevo SMTP login (if using SMTP)
- `BREVO_SMTP_PASS` — Brevo SMTP key/password (if using SMTP)

Other optional variables:
- `PORT` — Render will set this automatically. The server reads `process.env.PORT`.
- `NODE_ENV` — set to `production` on Render.

Security: do NOT put real keys in `server/.env.example`. Never commit `server/.env`.

## Render UI steps (manual)

1. Open Render → your service (aid-app-final-version).
2. Go to the **Environment** (Environment Variables) section.
3. Add the keys from above. Paste values exactly — no leading/trailing spaces or newlines.
4. Save and then trigger a **Manual Deploy** (Deploys → Manual Deploy → branch: `main`).

Render will build and start the service. Watch Live Logs during the deploy and the first requests.

## Test endpoints (after deploy)

Replace `https://aid-app-final-version.onrender.com` with your actual Render URL if different.

Health check (curl):

```bash
curl -i https://aid-app-final-version.onrender.com/health
```

Health check (PowerShell):

```powershell
Invoke-RestMethod -Uri "https://aid-app-final-version.onrender.com/health" -Method Get
```

Debug: TCP check for SMTP connectivity (optional)
```powershell
Invoke-RestMethod -Uri "https://aid-app-final-version.onrender.com/api/debug/smtp-check" -Method Get
```

Send a test SOS (PowerShell):

```powershell
$body = @{
  recipients = @("you@example.com")
  message = "Test SOS from Brevo HTTP API (production verification)"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://aid-app-final-version.onrender.com/api/send-sos-email" -Method Post -Headers @{ "Content-Type" = "application/json" } -Body $body
```

Send a test SOS (curl):

```bash
curl -X POST "https://aid-app-final-version.onrender.com/api/send-sos-email" \
  -H 'Content-Type: application/json' \
  -d '{"recipients":["you@example.com"],"message":"Test SOS from Brevo HTTP API"}'
```

Expected response (HTTP API path):

```json
{ "success": true, "via": "brevo_http", "message": "SOS email sent successfully" }
```

If the server falls back to SMTP and Render blocks outbound SMTP, `/api/debug/smtp-check` will return `{ ok: false, info: { error: 'timeout' } }`.

## Troubleshooting mapping

- 401 / 403 from Brevo HTTP API: invalid or expired `BREVO_API_KEY`. Rotate/regenerate key in Brevo and update Render.
- 429 from Brevo HTTP API: rate-limited — check account limits and backoff.
- ETIMEDOUT on SMTP/`debug/smtp-check`: Render does not allow outbound SMTP on your plan; use HTTP API (`BREVO_API_KEY`) instead.
- Missing env vars: server will warn in logs and return HTTP 500 for send attempts.

## Security checklist

- Ensure `server/.env` is listed in `.gitignore`.
- If secrets were ever committed, rotate them immediately in Brevo and update Render.
- Limit who has access to the Render service and rotate keys on a schedule.

## Optional next steps
- Add observability: log successful sends with requestId so you can correlate production test runs.
- Add a small CI step to run a lint or node startup check on PRs before merging.

If you want, I can add a simple `pino` log line after successful sends to include `requestId` and `via` in the logs. Ask and I’ll add it and push.
