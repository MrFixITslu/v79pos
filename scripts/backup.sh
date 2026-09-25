#!/usr/bin/env sh
set -eu
: "${DATABASE_URL:?DATABASE_URL is required}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BACKUP_DIR"
OUT="$BACKUP_DIR/v79commerce-$STAMP.dump"
pg_dump --format=custom --no-owner --no-acl --dbname="$DATABASE_URL" --file="$OUT"
sha256sum "$OUT" > "$OUT.sha256"
find "$BACKUP_DIR" -type f -name 'v79commerce-*.dump*' -mtime +"${BACKUP_RETENTION_DAYS:-30}" -delete
printf '%s\n' "$OUT"
