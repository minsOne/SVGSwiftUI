#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/browser-oracle-manifest.json"
OUTPUT_PATH="Examples/SVGSwiftUIDemo/UITests/BrowserBaselines"
REFERENCE_BASELINE_DIR=""
TOP_N=""

while (("$#")); do
    case "$1" in
        --output)
            OUTPUT_PATH="${2:-}"
            shift 2
            ;;
        --top-n)
            TOP_N="${2:-}"
            shift 2
            ;;
        --reference-baseline-dir)
            REFERENCE_BASELINE_DIR="${2:-}"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--output <path>] [--top-n <number>] [--reference-baseline-dir <path>]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--output <path>] [--top-n <number>] [--reference-baseline-dir <path>]" >&2
            exit 1
            ;;
    esac
done

mkdir -p "$OUTPUT_PATH"

node "$SCRIPT_DIR/render-browser-baselines.mjs" \
    --manifest "$MANIFEST_PATH" \
    --output "$OUTPUT_PATH" \
    ${TOP_N:+--top-n "$TOP_N"} \
    ${REFERENCE_BASELINE_DIR:+--reference-baseline-dir "$REFERENCE_BASELINE_DIR"}
