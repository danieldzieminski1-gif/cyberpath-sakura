#!/usr/bin/env bash
# Generates the Android project (the repo ships only Dart code) and patches the
# manifest so the RELEASE apk can reach the internet. Used by CI and build_apk.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --platforms=android --org com.cyberpath --project-name cyberpath .
  # flutter create may touch template files; keep our own versions.
  git checkout -- lib test pubspec.yaml 2>/dev/null || true
fi

M=android/app/src/main/AndroidManifest.xml
for perm in INTERNET ACCESS_NETWORK_STATE; do
  if ! grep -q "android.permission.$perm" "$M"; then
    sed -i "0,/<application/s||<uses-permission android:name=\"android.permission.$perm\"/>\n    <application|" "$M"
  fi
done
sed -i 's/android:label="cyberpath"/android:label="CyberPath"/' "$M"
echo "Android project ready. Permissions:"
grep "uses-permission" "$M"
