# Langflow on Railway

Wrapper image for the [Langflow](https://github.com/langflow-ai/langflow) visual
AI workflow / agent builder, built for Railway.

Upstream image, pinned by digest: `langflowai/langflow` 1.11.4.

What this wrapper adds:

- **It boots.** Upstream bakes `LANGFLOW_AUTO_LOGIN=false`, and with no
  superuser credentials set the app raises
  `ValueError: Username and password must be set` and gunicorn's worker exits 3.
  This image requires `LANGFLOW_SUPERUSER_PASSWORD` and fails fast with a clear
  message instead of crash-looping.
- **Volume permissions.** Railway mounts volumes owned by uid 0; the image runs
  as uid 1000. The entrypoint repairs `/app/data` as root, then drops
  privileges with `setpriv`.
- **Password rotation.** Langflow creates the superuser once and offers no way
  to change the password afterwards (its CLI needs an auth token, and password
  reset needs SMTP a fresh deploy does not have). The entrypoint re-applies the
  hash on every boot, so a redeploy is a working reset.
- **`$PORT` honoured**, so Railway's healthcheck and its edge proxy agree.

| Variable | Purpose |
| --- | --- |
| `LANGFLOW_SUPERUSER` | Admin username (default `admin`) |
| `LANGFLOW_SUPERUSER_PASSWORD` | Admin password — required |
| `LANGFLOW_SECRET_KEY` | Encrypts stored credentials; keep it stable |
| `LANGFLOW_DATABASE_URL` | Postgres connection string (use the private URL) |

Volume mount path: `/app/data`.
