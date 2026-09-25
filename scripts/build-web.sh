#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /tmp/flutter
  export PATH="/tmp/flutter/bin:$PATH"
fi

flutter config --enable-web
cd apps/web
flutter pub get
flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL:-https://securebypay-api.onrender.com/api}"

