# Server (Express) — always-there-aid

This folder contains the backend server for Always There Aid. It exposes a small API used by the frontend/mobile apps.

## Quick start (local)

1. Install dependencies from the `server/` folder:

```powershell
cd server
npm install
```

2. Create a `.env` file locally or set env vars in your shell. You can copy the example:

```powershell
copy .env.example .env
# edit .env and add values
```

3. Start the server:

```powershell
npm start
```

4. Health check:

```powershell
Invoke-RestMethod -Uri 'http://localhost:5000/health' -Method GET
```

5. Send an SOS email via SendGrid (requires `SENDGRID_API_KEY` and `SENDER_EMAIL` set):

```powershell
$body = @{ recipients = @('a@example.com','b@example.com'); message='Test SOS' } | ConvertTo-Json
Invoke-RestMethod -Uri 'http://localhost:5000/api/send-sos-email' -Method POST -ContentType 'application/json' -Body $body
```

## Environment variables

- `SENDGRID_API_KEY` — SendGrid API key used for sending emails. Add this as a secret on Render/Railway.
- `SENDER_EMAIL` — The verified sender email address.
- `PORT` — Optional. Defaults to `5000`.
- `NODE_ENV` — Optional. Set to `production` in production.

Optional extras:
- `REDIS_URL` — Connection string for Redis if you later implement a token store across instances.

## Deploying to Render

- We include a `render.yaml` at the repository root that configures the `server` subfolder. On Render, set the `SENDGRID_API_KEY` and `SENDER_EMAIL` values in the service Environment settings.
- Ensure Health Check Path is `/health`.

## Security notes

- Do NOT commit `.env` or any secrets to git. Use Render secrets or environment variables.
- Rotate SendGrid API keys if they are exposed.

## Extending the server

- `sendgrid.js` provides a lightweight wrapper around `@sendgrid/mail`. Reuse it wherever you need to send emails.
- Consider implementing a token-based SMTP flow or adding rate limiting (`express-rate-limit`) to protect endpoints.

## Troubleshooting

- If the service starts but health checks fail, check the logs in Render for uncaught exceptions. Ensure `PORT` is not hard-coded.
- If SendGrid returns an authentication error, verify the API key and that `SENDER_EMAIL` is a verified sender in SendGrid.
