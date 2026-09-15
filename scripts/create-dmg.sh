#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

app_path=""
output_path="$repo_root/dist/Ampere.dmg"
volume_name="Ampere"
icon_size=144
window_left=120
window_top=120
window_right=680
window_bottom=600
app_x=165
app_y=135
applications_x=395
applications_y=135

usage() {
  cat <<'USAGE'
Usage: scripts/create-dmg.sh --app /path/to/Ampere.app [options]

Options:
  --app PATH             Built Ampere.app bundle to package.
  --output PATH          Output DMG path. Defaults to dist/Ampere.dmg.
  --volume-name NAME     Mounted volume name. Defaults to Ampere.
  --icon-size PX         Finder icon size. Defaults to 144.
  --help                 Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      app_path="${2:-}"
      shift 2
      ;;
    --output)
      output_path="${2:-}"
      shift 2
      ;;
    --volume-name)
      volume_name="${2:-}"
      shift 2
      ;;
    --icon-size)
      icon_size="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ -z "$app_path" ]]; then
  echo "Missing --app /path/to/Ampere.app" >&2
  usage >&2
  exit 64
fi

if [[ ! -d "$app_path" || "${app_path##*.}" != "app" ]]; then
  echo "App bundle not found: $app_path" >&2
  exit 66
fi

if ! [[ "$icon_size" =~ ^[0-9]+$ ]]; then
  echo "--icon-size must be a number" >&2
  exit 64
fi

app_name="$(basename "$app_path")"
output_dir="$(dirname "$output_path")"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ampere-dmg.XXXXXX")"
staging_dir="$tmp_dir/staging"
mount_dir=""
patch_mount_dir="$tmp_dir/patch"
verification_mount_dir="$tmp_dir/verify"
rw_dmg="$tmp_dir/Ampere-rw.dmg"
mounted_device=""

cleanup() {
  if [[ -n "$mounted_device" ]]; then
    hdiutil detach "$mounted_device" -quiet >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$staging_dir" "$output_dir"

if [[ -e "/Volumes/$volume_name" ]]; then
  echo "A volume named '$volume_name' is already mounted. Eject it before creating the DMG." >&2
  exit 65
fi

ditto --rsrc --extattr "$app_path" "$staging_dir/$app_name"
ln -s /Applications "$staging_dir/Applications"

staging_kb="$(du -sk "$staging_dir" | awk '{print $1}')"
image_size_mb=$((staging_kb / 1024 + 64))
if [[ "$image_size_mb" -lt 128 ]]; then
  image_size_mb=128
fi

hdiutil create "$rw_dmg" \
  -volname "$volume_name" \
  -srcfolder "$staging_dir" \
  -fs HFS+ \
  -format UDRW \
  -size "${image_size_mb}m" \
  -quiet

attach_output="$(hdiutil attach "$rw_dmg" \
  -readwrite \
  -noautoopen \
  -noverify)"

mounted_device="$(printf '%s\n' "$attach_output" | awk '/Apple_HFS/ {print $1; exit}')"
mount_dir="$(printf '%s\n' "$attach_output" | sed -nE 's#^/dev/[^[:space:]]+[[:space:]]+Apple_HFS[[:space:]]+(.+)$#\1#p' | head -n 1)"

if [[ -z "$mounted_device" || -z "$mount_dir" ]]; then
  echo "Failed to mount writable DMG." >&2
  exit 1
fi

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$volume_name"
    open
    delay 3
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set pathbar visible of container window to false
    set the bounds of container window to {$window_left, $window_top, $window_right, $window_bottom}
    set arrangement of icon view options of container window to not arranged
    set icon size of icon view options of container window to $icon_size
    set text size of icon view options of container window to 13
    set position of item "$app_name" of container window to {$app_x, $app_y}
    set position of item "Applications" of container window to {$applications_x, $applications_y}
    update without registering applications
    delay 1
  end tell
  eject disk "$volume_name"
end tell
APPLESCRIPT

mounted_device=""
mount_dir=""

mkdir -p "$patch_mount_dir"
mounted_device="$(hdiutil attach "$rw_dmg" \
  -readwrite \
  -nobrowse \
  -noautoopen \
  -noverify \
  -mountpoint "$patch_mount_dir" \
  | awk '/Apple_HFS/ {print $1; exit}')"

if [[ -z "$mounted_device" ]]; then
  echo "Failed to re-mount DMG for layout patching." >&2
  exit 1
fi

if [[ ! -f "$patch_mount_dir/.DS_Store" ]]; then
  echo "Finder did not write DMG layout metadata." >&2
  exit 1
fi

python3 "$repo_root/scripts/patch-ds-store-tab-view.py" "$patch_mount_dir/.DS_Store"
hdiutil detach "$mounted_device" -quiet
mounted_device=""
sync

mkdir -p "$verification_mount_dir"
mounted_device="$(hdiutil attach "$rw_dmg" \
  -readonly \
  -nobrowse \
  -noautoopen \
  -noverify \
  -mountpoint "$verification_mount_dir" \
  | awk '/Apple_HFS/ {print $1; exit}')"

if [[ -z "$mounted_device" ]]; then
  echo "Failed to re-mount DMG for layout verification." >&2
  exit 1
fi

if [[ ! -f "$verification_mount_dir/.DS_Store" ]]; then
  echo "Finder layout metadata is missing after patching." >&2
  exit 1
fi

hdiutil detach "$mounted_device" -quiet
mounted_device=""

rm -f "$output_path"
hdiutil convert "$rw_dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$output_path" \
  -quiet

hdiutil verify "$output_path" -quiet

echo "Created $output_path"
