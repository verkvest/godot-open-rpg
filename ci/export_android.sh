#!/usr/bin/env bash
# Export a release (or debug-signed fallback) APK and AAB with targetSdk 36.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-godot}"
OUT="${OUT:-build/android}"
mkdir -p "$OUT"

VERSION_CODE="${GITHUB_RUN_NUMBER:-1}"
sed -i "s#^version/code=.*#version/code=${VERSION_CODE}#" export_presets.cfg

JAVA_HOME="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
export JAVA_HOME
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/android-sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export GRADLE_OPTS="${GRADLE_OPTS:--Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx2g}"

KEYSTORE_DIR="$HOME/.local/share/godot/keystores"
mkdir -p "$KEYSTORE_DIR"
DEBUG_KS="$KEYSTORE_DIR/debug.keystore"
if [ ! -f "$DEBUG_KS" ]; then
  keytool -genkeypair -v \
    -keystore "$DEBUG_KS" \
    -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android \
    -dname "CN=Android Debug,O=Android,C=US"
fi

# Let Godot create its editor settings, then point them at the SDK.
"$GODOT" --headless --path "$ROOT" --import --quit || "$GODOT" --headless --path "$ROOT" --import || true
SETTINGS="$(find "$HOME/.config/godot" -name 'editor_settings-4*.tres' 2>/dev/null | sort | tail -1 || true)"
if [ -z "$SETTINGS" ]; then
  mkdir -p "$HOME/.config/godot"
  SETTINGS="$HOME/.config/godot/editor_settings-4.7.tres"
  printf '%s\n' '[gd_resource type="EditorSettings" format=3]' '' '[resource]' > "$SETTINGS"
fi
python3 - "$SETTINGS" "$ANDROID_HOME" "$JAVA_HOME" "$DEBUG_KS" << 'PY'
import sys
path, sdk, java, keystore = sys.argv[1:]
text = open(path, encoding="utf-8", errors="replace").read()
if "[resource]" not in text:
    text += "\n[resource]\n"
updates = {
    "export/android/android_sdk_path": sdk,
    "export/android/java_sdk_path": java,
    "export/android/debug_keystore": keystore,
    "export/android/debug_keystore_user": "androiddebugkey",
    "export/android/debug_keystore_pass": "android",
}
lines = text.splitlines()
keys_done = set()
out = []
for line in lines:
    replaced = False
    for key, value in updates.items():
        if line.startswith(key + " ") or line.startswith(key + "="):
            out.append(f'{key} = "{value}"')
            keys_done.add(key)
            replaced = True
            break
    if not replaced:
        out.append(line)
if len(keys_done) < len(updates):
    if out and out[-1] != "":
        out.append("")
    for key, value in updates.items():
        if key not in keys_done:
            out.append(f'{key} = "{value}"')
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
print("editor settings", path)
PY

MODE="debug"
if [ -n "${ANDROID_KEYSTORE_B64:-}" ] && [ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ] && [ -n "${ANDROID_KEY_ALIAS:-}" ]; then
  MODE="release"
  RELEASE_KS="$HOME/quillfen-release.keystore"
  printf '%s' "$ANDROID_KEYSTORE_B64" | base64 --decode > "$RELEASE_KS"
  chmod 600 "$RELEASE_KS"
  python3 - "$ROOT/.godot/export_credentials.cfg" "$RELEASE_KS" "$ANDROID_KEY_ALIAS" "$ANDROID_KEYSTORE_PASSWORD" << 'PY'
import sys
path, keystore, alias, password = sys.argv[1:]
# Preset 1 is the Android preset in export_presets.cfg.
text = f'''[preset.1]

keystore/release="{keystore}"
keystore/release_user="{alias}"
keystore/release_password="{password}"
'''
open(path, "w", encoding="utf-8").write(text)
print("wrote release credentials")
PY
else
  echo "No release keystore secrets; exporting a debug-signed APK and AAB."
fi

export_one() {
  local format="$1"
  local dest="$2"
  sed -i "s#^gradle_build/export_format=.*#gradle_build/export_format=${format}#" export_presets.cfg
  if [ "$MODE" = "release" ]; then
    "$GODOT" --headless --path "$ROOT" --export-release "Android" "$dest"
  else
    "$GODOT" --headless --path "$ROOT" --export-debug "Android" "$dest"
  fi
  test -s "$dest"
  echo "exported $dest ($(du -h "$dest" | awk '{print $1}'))"
}

export_one 0 "$OUT/quillfen.apk"
export_one 1 "$OUT/quillfen.aab"
echo "Android export finished ($MODE, versionCode $VERSION_CODE, targetSdk 36)."
