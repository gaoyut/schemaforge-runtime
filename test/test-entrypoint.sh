#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FAKE_FLYWAY="$ROOT_DIR/test/fake-flyway"

output=$(
  FLYWAY_BIN="$FAKE_FLYWAY" \
  FLYWAY_URL="jdbc:jtds:sybase://localhost:5000/example" \
  FLYWAY_USER="test-user" \
  FLYWAY_PASSWORD="test-password" \
  "$ROOT_DIR/bin/schemaforge" validate
)

[ "$output" = "flyway-command=validate" ]

if FLYWAY_BIN="$FAKE_FLYWAY" "$ROOT_DIR/bin/schemaforge" migrate >/dev/null 2>&1; then
  echo "expected missing credentials to fail" >&2
  exit 1
fi

echo "entrypoint tests passed"
