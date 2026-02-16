#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: package-release.sh [--version <version>] [--output <directory>]

Options:
  --version <version>   Version for the packaged artifact (default: git tag or "local")
  --output <directory>  Output directory for release artifacts (default: build/xcframework)
  -h, --help           Show this help message
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${SVG_SWIFTUI_RELEASE_VERSION:-}"
OUTPUT_DIR="build/xcframework"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$VERSION" ]]; then
    VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
fi

if [[ -z "$VERSION" ]]; then
    VERSION="local"
fi

IOS_ARCHIVE="$OUTPUT_DIR/archives/SVGSwiftUI-iOS.xcarchive"
SIM_ARCHIVE="$OUTPUT_DIR/archives/SVGSwiftUI-iOS-Simulator.xcarchive"
XCFRAMEWORK_PATH="$OUTPUT_DIR/SVGSwiftUI.xcframework"
ZIP_NAME="SVGSwiftUI-${VERSION}.xcframework.zip"
ZIP_PATH="$OUTPUT_DIR/$ZIP_NAME"

mkdir -p "$OUTPUT_DIR/archives"
rm -rf "$IOS_ARCHIVE" "$SIM_ARCHIVE" "$XCFRAMEWORK_PATH" "$ZIP_PATH" "$OUTPUT_DIR/$ZIP_NAME.sha256"

build_archive() {
    local destination="$1"
    local archive_path="$2"

    echo "Building archive for destination: $destination"
    xcodebuild \
        -workspace .swiftpm/xcode/package.xcworkspace \
        -scheme SVGSwiftUI \
        -destination "$destination" \
        -archivePath "$archive_path" \
        SKIP_MACRO_VALIDATION=YES \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        clean archive
}

build_archive "generic/platform=iOS" "$IOS_ARCHIVE"
build_archive "generic/platform=iOS Simulator" "$SIM_ARCHIVE"

echo "Creating XCFramework"
xcodebuild -create-xcframework \
    -framework "$IOS_ARCHIVE/Products/usr/local/lib/SVGSwiftUI.framework" \
    -framework "$SIM_ARCHIVE/Products/usr/local/lib/SVGSwiftUI.framework" \
    -output "$XCFRAMEWORK_PATH"

echo "Packaging zip: $ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_PATH" "$ZIP_PATH"

if [[ -x "$(command -v swift)" ]]; then
    echo "Computing checksum for release artifact"
    swift package compute-checksum "$ZIP_PATH" > "$ZIP_PATH.sha256"
fi

echo "Release package completed"
echo "XCFramework: $XCFRAMEWORK_PATH"
echo "ZIP: $ZIP_PATH"
