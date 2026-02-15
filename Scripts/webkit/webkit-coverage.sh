#!/usr/bin/env bash
set -euo pipefail

MANIFEST=${1:-}
OUTPUT=${2:-}
STRICT_FLAG=${3:-}

if [[ -z "$MANIFEST" || -z "$OUTPUT" ]]; then
  cat <<USAGE
Usage: ./Scripts/webkit/webkit-coverage.sh <manifest-path> <output-path> [--strict]

Examples:
  ./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md
  ./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict
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

mkdir -p "$(dirname "$OUTPUT")"

python3 - "$MANIFEST" "$OUTPUT" "$STRICT_FLAG" <<'PY'
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
import sys


manifest_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
strict_mode = str(sys.argv[3]).strip().lower() == "--strict"
root_dir = manifest_path.parent

with manifest_path.open("r", encoding="utf-8") as handle:
    manifest = json.load(handle)

fixtures = manifest.get("fixtures", [])
total_fixtures = len(fixtures)

suite_stats = defaultdict(
    lambda: defaultdict(
        lambda: {
            "pass": 0,
            "fail": 0,
            "unsupported": 0,
            "missingSvg": 0,
            "missingRef": 0,
            "total": 0,
        }
    )
)

entries = []
overall = {"pass": 0, "fail": 0, "unsupported": 0, "total": total_fixtures}
missing_svg = 0
missing_reference = 0
invalid_mode_count = 0
invalid_expected_count = 0
duplicate_fixture_ids: list[str] = []
empty_id_count = 0
seen_fixture_ids = set()


def normalize_value(raw: str, valid: set[str], fallback: str) -> tuple[str, bool]:
    value = str(raw or fallback).lower()
    if value not in valid:
        return fallback, False
    return value, True


for item in fixtures:
    raw_id = str(item.get("id", "")).strip()
    if not raw_id:
        empty_id_count += 1
        fixture_id = f"fixture-{len(entries)}"
    else:
        fixture_id = raw_id

    if fixture_id in seen_fixture_ids:
        duplicate_fixture_ids.append(fixture_id)
    else:
        seen_fixture_ids.add(fixture_id)

    suite = str(item.get("suite", "unknown"))
    category = str(item.get("category", "general"))
    mode, mode_is_valid = normalize_value(
        item.get("mode", "parse"),
        {"parse", "render"},
        "parse",
    )
    expected, expected_is_valid = normalize_value(
        item.get("expected", "pass"),
        {"pass", "fail", "unsupported"},
        "unsupported",
    )
    if not mode_is_valid:
        invalid_mode_count += 1
    if not expected_is_valid:
        invalid_expected_count += 1

    svg = str(item.get("svg", ""))
    reference = str(item.get("reference", ""))
    source = str(item.get("source", ""))

    svg_path = root_dir / svg
    reference_path = root_dir / reference if reference else None
    svg_exists = bool(svg and svg_path.exists())
    reference_exists = bool(reference and reference_path.exists())

    if not svg_exists:
        missing_svg += 1
    if reference and not reference_exists:
        missing_reference += 1

    stat = suite_stats[suite][category]
    stat["total"] += 1
    if expected == "pass":
        stat["pass"] += 1
    elif expected == "fail":
        stat["fail"] += 1
    else:
        stat["unsupported"] += 1

        if not svg_exists:
            stat["missingSvg"] += 1
    if reference and not reference_exists:
        stat["missingRef"] += 1

    overall[expected] += 1

    entries.append(
        {
            "id": fixture_id,
            "suite": suite,
            "category": category,
            "mode": mode,
            "expected": expected,
            "svg": svg,
            "reference": reference,
            "svgExists": svg_exists,
            "referenceExists": reference_exists,
            "source": source,
        }
    )

if overall["pass"] + overall["fail"] + overall["unsupported"] != total_fixtures:
    overall["unsupported"] = max(0, total_fixtures - overall["pass"] - overall["fail"])


def format_percent(value: int, total: int) -> str:
    if total == 0:
        return "0.0%"
    ratio = (value / total) * 100.0
    return f"{ratio:.1f}%"


lines = []
lines.append("# WebKit LayoutTests Conformance Coverage\n")
lines.append(f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%SZ')} UTC\n")
lines.append(f"Manifest: `{manifest_path.as_posix()}`\n")
lines.append(f"- Total fixtures: {total_fixtures}\n")
lines.append(f"- Missing SVG resources: {missing_svg}\n")
lines.append(f"- Missing reference resources: {missing_reference}\n")
lines.append("\n")
lines.append("## Expected Status Summary\n")
lines.append("| Suite | Category | Total | Pass | Fail | Unsupported | Missing SVG | Missing Reference |\n")
lines.append("|---|---|---:|---:|---:|---:|---:|---:|\n")
for suite in sorted(suite_stats.keys()):
    for category in sorted(suite_stats[suite].keys()):
        stat = suite_stats[suite][category]
        lines.append(
            f"| {suite} | {category} | {stat['total']} | {stat['pass']} | {stat['fail']} | "
            f"{stat['unsupported']} | {stat['missingSvg']} | {stat['missingRef']} |\n"
        )
lines.append("\n")
lines.append("## Coverage by Expected Result\n")
lines.append("| Result | Count | Coverage |\n")
lines.append("|---|---:|---:|\n")
lines.append(f"| pass | {overall['pass']} | {format_percent(overall['pass'], total_fixtures)} |\n")
lines.append(f"| fail | {overall['fail']} | {format_percent(overall['fail'], total_fixtures)} |\n")
lines.append(f"| unsupported | {overall['unsupported']} | {format_percent(overall['unsupported'], total_fixtures)} |\n")
lines.append("\n")
lines.append("## Conformance Health Check\n")
lines.append(f"- Invalid fixture mode values: {invalid_mode_count}\n")
lines.append(f"- Invalid fixture expected values: {invalid_expected_count}\n")
lines.append(f"- Empty fixture IDs: {empty_id_count}\n")
lines.append(f"- Duplicate fixture IDs: {len(duplicate_fixture_ids)}\n")
for duplicate_id in sorted(set(duplicate_fixture_ids)):
    lines.append(f"  - {duplicate_id}\n")
lines.append(f"- Strict mode: {'enabled' if strict_mode else 'disabled'}\n")
lines.append(f"- Source field valid count: {sum(1 for entry in entries if bool(entry['source']))}\n")
lines.append("\n")
lines.append("## Fixture Table\n")
lines.append("| ID | Suite | Category | Mode | Expected | SVG | Reference | Source | SVG Resource | Reference Resource |\n")
lines.append("|---|---|---|---|---|---|---|---|---|---|\n")
for item in entries:
    svg_mark = "✅" if item["svgExists"] else "❌"
    has_reference = bool(item["reference"])
    if has_reference:
        ref_mark = "✅" if item["referenceExists"] else "❌"
    else:
        ref_mark = "N/A"
    lines.append(
        f"| {item['id']} | {item['suite']} | {item['category']} | {item['mode']} | "
        f"{item['expected']} | `{item['svg']}` | `{item['reference']}` | `{item['source']}` | {svg_mark} | {ref_mark} |\n"
    )

lines.append("\n")
lines.append("- pass/fail/unsupported are derived from manifest `expected` field.\n")
lines.append("- Source URL/path is informational; local fixtures should be generated or committed under WebKit/fixtures.\n")

if strict_mode:
    has_strict_error = (
        missing_svg > 0
        or missing_reference > 0
        or invalid_mode_count > 0
        or invalid_expected_count > 0
        or empty_id_count > 0
        or duplicate_fixture_ids
    )
    lines.append("\n")
    lines.append("## Strict Mode Validation\n")
    lines.append(f"- strict mode failed: {'true' if has_strict_error else 'false'}\n")
    if has_strict_error:
        lines.append(f"- missing_svg={missing_svg}\n")
        lines.append(f"- missing_reference={missing_reference}\n")
        lines.append(f"- invalid_mode_count={invalid_mode_count}\n")
        lines.append(f"- invalid_expected_count={invalid_expected_count}\n")
        lines.append(f"- empty_id_count={empty_id_count}\n")
        lines.append(f"- duplicate_fixture_ids={len(duplicate_fixture_ids)}\n")

output_path.write_text("".join(lines), encoding="utf-8")
print(f"Generated coverage report -> {output_path}")

if strict_mode and (
    missing_svg > 0
    or missing_reference > 0
    or invalid_mode_count > 0
    or invalid_expected_count > 0
    or empty_id_count > 0
    or duplicate_fixture_ids
):
    raise SystemExit(1)
PY
