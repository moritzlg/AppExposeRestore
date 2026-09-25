#!/bin/zsh
set -euo pipefail

root_dir="${0:A:h}"
test_dir="$(mktemp -d /private/tmp/app-expose-restore-tests.XXXXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
developer_dir="/Applications/Xcode.app/Contents/Developer"
if [[ ! -d "$developer_dir" ]]; then
  developer_dir="$(xcode-select -p)"
fi
mkdir -p "$test_dir/modulecache"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$test_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$test_dir/modulecache" \
xcrun swiftc -parse-as-library -module-cache-path "$test_dir/modulecache" \
  "$root_dir/Sources/ExposeSurface.swift" "$root_dir/Tests/ExposeSurfaceTests.swift" \
  -o "$test_dir/expose-surface-tests"
"$test_dir/expose-surface-tests"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$test_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$test_dir/modulecache" \
xcrun swiftc -parse-as-library -module-cache-path "$test_dir/modulecache" \
  "$root_dir/Sources/WindowPreviewMatcher.swift" "$root_dir/Tests/WindowPreviewMatcherTests.swift" \
  -o "$test_dir/window-preview-matcher-tests"
"$test_dir/window-preview-matcher-tests"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$test_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$test_dir/modulecache" \
xcrun swiftc -parse-as-library -module-cache-path "$test_dir/modulecache" \
  "$root_dir/Sources/AccessibilityWindows.swift" "$root_dir/Sources/RestoreTrace.swift" \
  "$root_dir/Tests/AccessibilityWindowsTests.swift" \
  -o "$test_dir/accessibility-windows-tests"
"$test_dir/accessibility-windows-tests"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$test_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$test_dir/modulecache" \
xcrun swiftc -parse-as-library -module-cache-path "$test_dir/modulecache" \
  "$root_dir/Sources/AppPreferences.swift" "$root_dir/Tests/AppPreferencesTests.swift" \
  -o "$test_dir/app-preferences-tests"
"$test_dir/app-preferences-tests"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$test_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$test_dir/modulecache" \
xcrun swiftc -parse-as-library -module-cache-path "$test_dir/modulecache" \
  "$root_dir/Sources/PreviewViewport.swift" "$root_dir/Tests/PreviewViewportTests.swift" \
  -o "$test_dir/preview-viewport-tests"
"$test_dir/preview-viewport-tests"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$test_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$test_dir/modulecache" \
xcrun swiftc -module-cache-path "$test_dir/modulecache" \
  "$root_dir/Sources/AppPreferences.swift" "$root_dir/Sources/StripAppearance.swift" \
  "$root_dir/Sources/SettingsWindowController.swift" \
  "$root_dir/Tests/StripAppearanceTests.swift" \
  -o "$test_dir/strip-appearance-tests"
"$test_dir/strip-appearance-tests"
