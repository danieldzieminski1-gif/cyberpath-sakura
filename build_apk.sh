#!/usr/bin/env bash
# Builds an installable CyberPath APK. Requires Flutter (stable) + Android SDK + Java 17.
# Optional: LESSONS_URL=https://.../lessons.json ./build_apk.sh
set -euo pipefail
cd "$(dirname "$0")"
bash tool/prepare_android.sh
flutter pub get
flutter analyze --no-fatal-infos || true
flutter test || true
flutter build apk --release --no-tree-shake-icons --dart-define=LESSONS_URL="${LESSONS_URL:-}"
echo
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
