#!/usr/bin/env bash
set -euo pipefail

echo "[s3-profile] start"
echo "[s3-profile] repository: ${PWD}"
date -u

swift test --filter SVGRenderPerformanceProfileTests --no-parallel 2>&1 | tee s3-profile.log
echo "[s3-profile] log: s3-profile.log"
