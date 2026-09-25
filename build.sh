#!/bin/zsh
set -euo pipefail

root_dir="${0:A:h}"
archive_path="${root_dir:h}/AppExposeRestore.zip"
build_dir="$(mktemp -d /private/tmp/app-expose-restore.XXXXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
app_dir="$build_dir/AppExposeRestore.app"
developer_dir="/Applications/Xcode.app/Contents/Developer"
signing_identity="${APP_EXPOSE_SIGNING_IDENTITY:--}"
if [[ ! -d "$developer_dir" ]]; then
  developer_dir="$(xcode-select -p)"
fi
mkdir -p "$build_dir/modulecache" "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$root_dir/Info.plist" "$app_dir/Contents/Info.plist"
ditto "$root_dir/Resources" "$app_dir/Contents/Resources"
DEVELOPER_DIR="$developer_dir" \
CLANG_MODULE_CACHE_PATH="$build_dir/modulecache" \
SWIFT_MODULE_CACHE_PATH="$build_dir/modulecache" \
xcrun swiftc -O -module-cache-path "$build_dir/modulecache" \
  "$root_dir"/Sources/*.swift -o "$app_dir/Contents/MacOS/AppExposeRestore"
codesign --force --sign "$signing_identity" "$app_dir"
codesign --verify --deep --strict "$app_dir"
ditto -c -k --keepParent "$app_dir" "$archive_path"
echo "$archive_path"
