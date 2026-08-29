#!/usr/bin/env bash

set -Eeuo pipefail

readonly DUMP_DIR="${BATLAB_DUMP_DIR:-/mnt/docker-volumes/database-dumps}"
readonly PAPERLESS_DB_CONTAINER="${PAPERLESS_DB_CONTAINER:-paperless-db}"
readonly PAPERLESS_DUMP="$DUMP_DIR/paperless.dump"
readonly PAPERLESS_TMP="$PAPERLESS_DUMP.tmp"

command -v docker >/dev/null 2>&1 || {
  echo "Required command not found: docker" >&2
  exit 1
}

install -d -m 700 "$DUMP_DIR"
rm -f -- "$PAPERLESS_TMP"
trap 'rm -f -- "$PAPERLESS_TMP"' EXIT

if ! docker inspect "$PAPERLESS_DB_CONTAINER" >/dev/null 2>&1; then
  echo "Paperless database container is unavailable: $PAPERLESS_DB_CONTAINER" >&2
  exit 1
fi

echo "Exporting Paperless PostgreSQL database..."
umask 077
docker exec "$PAPERLESS_DB_CONTAINER" sh -ceu \
  'exec pg_dump --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --format=custom' \
  >"$PAPERLESS_TMP"

if [[ ! -s "$PAPERLESS_TMP" ]]; then
  echo "Paperless database export is empty" >&2
  exit 1
fi

mv -f -- "$PAPERLESS_TMP" "$PAPERLESS_DUMP"
trap - EXIT
echo "Created $PAPERLESS_DUMP ($(du -h "$PAPERLESS_DUMP" | cut -f1))"
