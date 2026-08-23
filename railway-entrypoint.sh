#!/bin/sh
# Boot Langflow on Railway.
#
# Three things upstream's image does not do for this platform:
#   1. It refuses to start when AUTO_LOGIN is false and no superuser credentials
#      are set (ValueError: Username and password must be set), so an empty
#      password has to fail loudly here rather than crash-loop later.
#   2. Railway mounts the volume as uid 0 while the image runs as uid 1000, so
#      the data directory has to be repaired before dropping privileges.
#   3. The superuser password can never be changed after the first boot, so it
#      is re-applied here on every boot.
set -eu

: "${LANGFLOW_SUPERUSER:=admin}"
export LANGFLOW_SUPERUSER

if [ -z "${LANGFLOW_SUPERUSER_PASSWORD:-}" ]; then
    echo "FATAL: LANGFLOW_SUPERUSER_PASSWORD is empty." >&2
    echo "Langflow runs with AUTO_LOGIN disabled and will not start without an admin password." >&2
    exit 1
fi

DATA_DIR="${HOME:-/app/data}"
mkdir -p "$DATA_DIR" "$LANGFLOW_CONFIG_DIR"
chown -R 1000:0 "$DATA_DIR"
echo "[boot] data dir $DATA_DIR owner=$(stat -c %u:%g "$DATA_DIR")"

PORT="${PORT:-7860}"
export LANGFLOW_PORT="$PORT"

DROP="setpriv --reuid=1000 --regid=0 --clear-groups"

$DROP python /usr/local/bin/rotate_superuser.py || true

exec $DROP langflow run --host 0.0.0.0 --port "$PORT"
