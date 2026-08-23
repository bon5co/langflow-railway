# Langflow for Railway — pinned, volume-safe, and bootable without manual setup.
#
# Upstream 1.11.4. The digest is pinned because Langflow runs alembic migrations
# forward on boot and Docker Hub currently publishes 1.12.0.devNN prereleases
# under moving tags.
FROM langflowai/langflow@sha256:3fe9a758b8a4fa9bbeec726d71d2f69391643bfc20c175288c1b4e166b7348fb

USER root

# Railway mounts volumes owned by uid 0; the upstream image runs as uid 1000.
ENV LANGFLOW_AUTO_LOGIN=false \
    HOME=/app/data \
    LANGFLOW_CONFIG_DIR=/app/data/.cache/langflow \
    DO_NOT_TRACK=1

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY rotate_superuser.py /usr/local/bin/rotate_superuser.py
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
