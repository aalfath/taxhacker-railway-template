#!/bin/bash
# Starts TaxHacker (localhost only), the Caddy basic-auth proxy on $PORT and the email-sync loop.
# The container exits as soon as one of them stops, so Railway's restart policy brings it back.
set -euo pipefail

export PORT="${PORT:-8080}"
export TAXHACKER_USERNAME="${TAXHACKER_USERNAME:-admin}"
export UPLOAD_PATH="${UPLOAD_PATH:-/app/data/uploads}"

if [ -z "${TAXHACKER_PASSWORD:-}" ]; then
  echo "TAXHACKER_PASSWORD is empty. Set it: TaxHacker has no login of its own in self-hosted mode." >&2
  exit 1
fi
if [ "${PORT}" = "7331" ]; then
  echo "PORT must not be 7331 (TaxHacker itself uses it on localhost)." >&2
  exit 1
fi

mkdir -p "${UPLOAD_PATH}"

# BETTER_AUTH_SECRET encrypts stored mailbox passwords. If unset, keep one on the volume.
if [ -z "${BETTER_AUTH_SECRET:-}" ]; then
  f=/app/data/.better_auth_secret
  [ -s "$f" ] || (umask 077; head -c 48 /dev/urandom | base64 | tr -d '\n/+=' > "$f")
  BETTER_AUTH_SECRET="$(cat "$f")"
  export BETTER_AUTH_SECRET
fi

TAXHACKER_PASSWORD_HASH="$(printf '%s' "${TAXHACKER_PASSWORD}" | caddy hash-password)"
export TAXHACKER_PASSWORD_HASH

# TaxHacker on localhost only. PORT is overridden for this process alone.
PORT=7331 HOSTNAME=127.0.0.1 /app/node_modules/.bin/next start -H 127.0.0.1 -p 7331 &

caddy run --config /app/railway/Caddyfile --adapter caddyfile &

# Same job as upstream's cron container: email sync every 5 minutes (it honours each mailbox's interval).
(
  sleep 120
  while true; do
    out="$(cd /app && npm run -s email:sync 2>&1)" || echo "email sync failed: ${out}" >&2
    sleep 300
  done
) &

wait -n
echo "A TaxHacker process stopped; exiting so Railway restarts the service." >&2
exit 1
