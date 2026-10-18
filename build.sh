#!/usr/bin/env sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCAL_GRADLE="$PROJECT_DIR/../gradle-8.14.6/bin/gradle"
if [ -x "$LOCAL_GRADLE" ]; then
  exec "$LOCAL_GRADLE" -p "$PROJECT_DIR" build --no-daemon
fi
if command -v gradle >/dev/null 2>&1; then
  exec gradle -p "$PROJECT_DIR" build --no-daemon
fi
echo "Gradle not found. Extract gradle-8.14.6 beside this project or install Gradle and add it to PATH." >&2
exit 1
