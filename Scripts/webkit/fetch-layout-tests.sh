#!/usr/bin/env bash
set -euo pipefail

MANIFEST=${1:-}
OUTPUT_DIR=${2:-Tests/SVGSwiftUITests/WebKit/fixtures}
REMOTE_BASE=${3:-https://raw.githubusercontent.com/WebKit/WebKit/main}

if [[ -z "$MANIFEST" ]]; then
  cat <<USAGE
Usage: ./Scripts/webkit/fetch-layout-tests.sh <manifest-path> [output-dir] [remote-base-url]

Examples:
  ./Scripts/webkit/fetch-layout-tests.sh \
    Tests/SVGSwiftUITests/WebKit/webkit-manifest.json \
    Tests/SVGSwiftUITests/WebKit/fixtures
USAGE
  exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest file not found: $MANIFEST" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required by this script." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

python3 - "$MANIFEST" "$OUTPUT_DIR" "$REMOTE_BASE" <<'PY'
import json
from pathlib import PurePosixPath
from pathlib import Path
from urllib.request import urlopen
from urllib.error import HTTPError
import sys


manifest_path = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
remote_base = sys.argv[3].rstrip("/")

with manifest_path.open("r", encoding="utf-8") as handle:
    manifest = json.load(handle)

fixtures = manifest.get("fixtures", [])
if not isinstance(fixtures, list):
    print("Invalid manifest: fixtures must be a list.", file=sys.stderr)
    sys.exit(1)


def normalize_fixture_path(value: str) -> str:
    clean_value = value.strip().lstrip("/")
    if not clean_value:
        return ""
    path = PurePosixPath(clean_value)
    if len(path.parts) > 1 and path.parts[0] == "fixtures":
        return str(path.relative_to("fixtures"))
    return str(path)


for fixture in fixtures:
    source_path = str(fixture.get("source", "")).strip()
    local_path = normalize_fixture_path(str(fixture.get("svg", "")).strip())
    fixture_id = str(fixture.get("id", "")).strip() or "unknown"

    if not source_path:
        print(f"Skipped fixture (missing source): {fixture_id}", file=sys.stderr)
        continue

    if not local_path:
        local_path = Path(source_path).name

    destination = output_dir / local_path
    destination.parent.mkdir(parents=True, exist_ok=True)

    source_url = source_path
    lower_url = source_url.lower()
    if not (lower_url.startswith("http://") or lower_url.startswith("https://")):
        source_url = f"{remote_base}/{source_path.lstrip('/')}"

    try:
        with urlopen(source_url) as response:
            data = response.read()
    except HTTPError as exc:
        print(f"Failed to fetch {source_path}: {exc.code}", file=sys.stderr)
        raise
    except Exception as exc:
        print(f"Failed to fetch {source_path}: {exc}", file=sys.stderr)
        raise

    destination.write_bytes(data)
    print(f"Fetched -> {destination}")
PY
