# TaxHacker for Railway: the official image plus a small Caddy front door with HTTP basic auth.
# TaxHacker's self-hosted mode has no login of its own, so the app listens only on localhost
# and Caddy (on $PORT) asks for TAXHACKER_USERNAME / TAXHACKER_PASSWORD before every request.
FROM caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b AS caddy

FROM ghcr.io/vas3k/taxhacker:0.8.5@sha256:465c8f4510063221352f779a3bf98d2badd56797424d788011eb8f4eba2e6015

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY railway/Caddyfile railway/start.sh /app/railway/
RUN chmod 755 /app/railway/start.sh

ENV NODE_ENV=production \
    SELF_HOSTED_MODE=true \
    UPLOAD_PATH=/app/data/uploads \
    XDG_CONFIG_HOME=/tmp/caddy-config \
    XDG_DATA_HOME=/tmp/caddy-data

EXPOSE 8080
# Upstream entrypoint waits for Postgres and runs `prisma migrate deploy`, then runs CMD.
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/app/railway/start.sh"]
