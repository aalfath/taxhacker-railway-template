[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/taxhacker-2?utm_medium=integration&utm_source=button&utm_campaign=taxhacker)

# TaxHacker on Railway

A one-click [Railway](https://railway.com) template for [TaxHacker](https://github.com/vas3k/TaxHacker), the self-hosted AI accounting app by vas3k: upload receipts, invoices and bank statements, and an LLM (OpenAI, Gemini, Mistral or any OpenAI-compatible endpoint) extracts merchants, amounts, taxes and items into a searchable transaction table.

## What it deploys

| Service | Source | Notes |
|---|---|---|
| `TaxHacker` | this repo's `Dockerfile` | `ghcr.io/vas3k/taxhacker:0.8.5` pinned by digest, plus Caddy 2.11.9 for login. Volume at `/app/data` (uploads, generated secret). Health check `/healthz`. |
| `Postgres` | Railway Postgres | TaxHacker's database (Prisma migrations run on every start). |

TaxHacker's self-hosted mode has **no login of its own**: anyone who reaches it is the owner. So this template keeps TaxHacker on `127.0.0.1:7331` inside the container and puts Caddy in front on `PORT` with HTTP basic auth. Only `/healthz` answers without a password (it returns a static icon once TaxHacker is up).

The container also runs upstream's email-sync job every 5 minutes (what upstream's separate `cron` container does), so mailbox import works without a second service.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `TAXHACKER_USERNAME` | `admin` | Basic-auth user name for the web UI. |
| `TAXHACKER_PASSWORD` | `${{secret(24)}}` | Basic-auth password, generated at deploy. Read it in the service's Variables tab. |
| `BETTER_AUTH_SECRET` | `${{secret(48)}}` | Encrypts stored mailbox passwords. Don't change it after setup. |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Private-network connection to Postgres. |
| `BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL of the app. |
| `PORT` | `8080` | Port Caddy listens on (not 7331). |

LLM API keys aren't template variables: TaxHacker asks for them on its first-run setup page and keeps them in Settings → LLM. You can still set `OPENAI_API_KEY`, `GOOGLE_API_KEY` or `MISTRAL_API_KEY` on the service if you prefer.

## First run

1. Open the service's public URL and sign in with `admin` and the generated `TAXHACKER_PASSWORD`.
2. TaxHacker's setup page asks for an LLM API key and your default currency.
3. Upload a receipt under **Unsorted** and click **Analyze**.

## Updates

Railway tells everyone who deployed this template when a change lands on this repo's `main` branch, and you choose when to apply it. Each change bumps the pinned image and is listed in [CHANGELOG.md](CHANGELOG.md), breaking changes first. Back up Postgres before applying an update: TaxHacker runs its database migrations on start.

## Licence

TaxHacker is MIT-licensed by vas3k. This wrapper is MIT too.
