#!/bin/sh
# Xcode Cloud: läuft nach dem Klonen, vor dem Archivieren.
# Installiert Flutter (feste Version wie in .gitlab-ci.yml), erzeugt die Flutter-Konfiguration
# mit Version/Build und installiert die Pods.
#
# Xcode-Cloud-Umgebungsvariablen: CI_PRIMARY_REPOSITORY_PATH, CI_BUILD_NUMBER, CI_TAG
# Anleitung: deploy/gitlab/README.md, Abschnitt "iOS mit Xcode Cloud"
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

FLUTTER_VERSION=$(sed -nE 's/^  FLUTTER_VERSION: "([^"]+)"/\1/p' .gitlab-ci.yml)
APP_VERSION=$(sed -nE 's/^version:[[:space:]]*([0-9.]+)\+?.*/\1/p' pubspec.yaml)
echo "Flutter $FLUTTER_VERSION, App $APP_VERSION, Build ${CI_BUILD_NUMBER:-?}, Tag ${CI_TAG:-–}"

# Tag muss zur pubspec-Version passen (wie release:verify in GitLab)
if [ -n "${CI_TAG:-}" ] && [ "$CI_TAG" != "v$APP_VERSION" ]; then
  echo "error: Tag $CI_TAG passt nicht zu pubspec.yaml (v$APP_VERSION)"
  exit 1
fi

git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter --disable-analytics >/dev/null 2>&1 || true
# Firebase kommt über CocoaPods; SPM zusätzlich führt zu "redefinition of module 'FirebaseCore'"
flutter config --no-enable-swift-package-manager
flutter precache --ios
flutter pub get

# Version/Build in Generated.xcconfig (das Vers-Widget übernimmt FLUTTER_BUILD_NUMBER)
flutter build ios --release --config-only --build-name="$APP_VERSION" --build-number="${CI_BUILD_NUMBER:-1}"

HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
cd ios && pod install
