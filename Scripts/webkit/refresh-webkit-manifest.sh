#!/usr/bin/env bash
set -euo pipefail

SUITE_NAME=${1:-W3C-SVG-1.1}
OUTPUT_MANIFEST=${2:-Tests/SVGSwiftUITests/WebKit/webkit-manifest.json}
MAX_FIXTURES=${3:-40}

INCLUDE_PREFIXES_DEFAULT="shapes,paths,coords,color,colors,styling,masking,filters"
PASS_PREFIXES_DEFAULT="shapes,paths,coords,color,colors,styling"

INCLUDE_PREFIXES=${WEBKIT_INCLUDE_PREFIXES:-$INCLUDE_PREFIXES_DEFAULT}
PASS_PREFIXES=${WEBKIT_PASS_PREFIXES:-$PASS_PREFIXES_DEFAULT}
REMOTE_API_BASE=${WEBKIT_REMOTE_API_BASE:-https://api.github.com/repos/WebKit/WebKit}

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required." >&2
  exit 1
fi

if ! [[ $MAX_FIXTURES =~ ^[0-9]+$ ]]; then
  echo "Invalid max fixtures: $MAX_FIXTURES" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_MANIFEST")"

python3 - "$SUITE_NAME" "$OUTPUT_MANIFEST" "$MAX_FIXTURES" "$INCLUDE_PREFIXES" "$PASS_PREFIXES" "$REMOTE_API_BASE" <<'PY'
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from urllib.parse import quote


def split_csv(raw_value):
    return [value.strip() for value in raw_value.split(",") if value.strip()]


def parse_next_link(header_value):
    if not header_value:
        return None
    for part in header_value.split(","):
        part = part.strip()
        if "rel=\"next\"" not in part:
            continue
        start = part.find("<")
        end = part.find(">")
        if start == -1 or end == -1:
            continue
        return part[start + 1 : end]
    return None


def suite_slug(suite_name):
    base = suite_name.strip()
    if base.upper().startswith("W3C-SVG-"):
        base = base[len("W3C-SVG-") :]
    if base.startswith("1."):
        return base
    if base.startswith("1-"):
        return base.replace("1-", "1.")
    return base


def normalize_filename(raw_name):
    return raw_name.lower().rsplit(".", 1)[0]


def category_for_prefix(prefix):
    mapping = {
        "animate": "animate",
        "color": "styling",
        "colors": "styling",
        "coords": "coords",
        "extend": "extend",
        "filters": "filter",
        "fonts": "fonts",
        "interact": "interact",
        "linking": "linking",
        "metadata": "metadata",
        "masking": "mask",
        "painting": "painting",
        "paths": "paths",
        "pservers": "paint-server",
        "render": "render",
        "script": "script",
        "shapes": "shapes",
        "styling": "styling",
        "struct": "structure",
        "text": "text",
        "types": "types",
    }
    return mapping.get(prefix, "misc")


def category_rank(category):
    order = {
        "shapes": 0,
        "paths": 1,
        "coords": 2,
        "styling": 3,
        "filter": 4,
        "mask": 5,
        "paint-server": 6,
        "paint": 7,
        "misc": 20,
    }
    return order.get(category, 19)


def matches_prefix(stem, prefixes):
    for prefix in prefixes:
        if stem == prefix:
            return prefix
        if stem.startswith(prefix + "-"):
            return prefix
    return None


def fetch_svg_files_from_webkit(suite_name, remote_api_base):
    files = []
    start_path = "LayoutTests/svg/{}/".format(quote(suite_name))
    url = remote_api_base + "/contents/" + start_path + "?ref=main"
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "SVGSwiftUI-webkit-refresh",
    }

    while url:
        request = Request(url, headers=headers)
        try:
            with urlopen(request) as response:
                payload = json.load(response)
                if not isinstance(payload, list):
                    raise RuntimeError("Unexpected API payload for {}".format(url))
                files.extend(payload)
                url = parse_next_link(response.headers.get("Link"))
        except HTTPError as error:
            raise RuntimeError("Failed to fetch {}: {}".format(url, error.code))
        except URLError as error:
            raise RuntimeError("Failed to fetch {}: {}".format(url, error))

    return files


def expected_mode(stem, pass_prefixes):
    for prefix in pass_prefixes:
        if stem == prefix:
            return "pass"
        if stem.startswith(prefix + "-"):
            return "pass"
    return "unsupported"


def build_manifest_entry(suite_name, item, existing_by_source, pass_prefixes):
    item_source = str(item.get("path", "")).strip()
    item_name = str(item.get("name", "")).strip()
    stem = normalize_filename(item_name)
    primary_prefix = stem.split("-", 1)[0]

    existing = existing_by_source.get(item_source)
    if existing is not None and "id" in existing:
        fixture_id = str(existing["id"])
    else:
        fixture_id = "webkit-{}-{}".format(suite_slug(suite_name), stem)

    if existing is not None:
        category = str(existing.get("category", "")) or category_for_prefix(primary_prefix)
        mode = str(existing.get("mode", "parse"))
        expected = str(existing.get("expected", expected_mode(stem, pass_prefixes)))
        svg_path = str(existing.get("svg", "fixtures/webkit-{}.svg".format(stem)))
        reference = str(existing.get("reference", ""))
    else:
        category = category_for_prefix(primary_prefix)
        mode = "parse"
        expected = expected_mode(stem, pass_prefixes)
        svg_path = "fixtures/webkit-{}.svg".format(stem)
        reference = ""

    return {
        "id": fixture_id,
        "suite": suite_name,
        "category": category,
        "mode": mode,
        "expected": expected,
        "svg": svg_path,
        "reference": reference,
        "source": item_source,
    }


def main():
    suite_name = sys.argv[1]
    output_manifest = Path(sys.argv[2])
    max_fixtures = int(sys.argv[3])
    include_prefixes = split_csv(sys.argv[4])
    pass_prefixes = split_csv(sys.argv[5])
    remote_api_base = sys.argv[6].rstrip("/")

    existing_by_source = {}
    if output_manifest.is_file():
        with output_manifest.open("r", encoding="utf-8") as handle:
            loaded = json.load(handle)
            existing_fixtures = loaded.get("fixtures", [])
            if isinstance(existing_fixtures, list):
                for item in existing_fixtures:
                    if not isinstance(item, dict):
                        continue
                    source = str(item.get("source", "")).strip()
                    if not source:
                        continue
                    existing_by_source[source] = {
                        str(key): str(value)
                        for key, value in item.items()
                        if isinstance(value, str)
                    }

    items = fetch_svg_files_from_webkit(suite_name, remote_api_base)

    entries = []
    for item in items:
        if str(item.get("type", "")).lower() != "file":
            continue
        raw_name = str(item.get("name", "")).strip()
        if not raw_name.lower().endswith(".svg"):
            continue
        stem = normalize_filename(raw_name)
        if matches_prefix(stem, include_prefixes) is None:
            continue
        entries.append(
            build_manifest_entry(
                suite_name=suite_name,
                item=item,
                existing_by_source=existing_by_source,
                pass_prefixes=pass_prefixes,
            )
        )

    entries.sort(key=lambda item: (
        category_rank(item["category"]),
        item["category"],
        item["id"],
    ))

    if max_fixtures > 0 and len(entries) > max_fixtures:
        entries = entries[:max_fixtures]

    with output_manifest.open("w", encoding="utf-8") as handle:
        json.dump({"fixtures": entries}, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    print("Generated {} fixtures -> {}".format(len(entries), output_manifest))


if __name__ == "__main__":
    main()
PY
