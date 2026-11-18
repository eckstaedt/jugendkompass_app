#!/usr/bin/env bash
# Stellt die in FLUTTER_VERSION festgelegte Flutter-Version bereit und setzt PATH.
# Wird per `source .gitlab/ci/flutter-env.sh` in den CI-Jobs geladen.
#
# Linux (Docker-Runner): SDK liegt im GitLab-Cache unter .cache/flutter/<version>.
# macOS (Shell-Runner):  SDK liegt dauerhaft unter ~/.flutter-sdks/<version>.


# Läuft im Job-Shell von GitLab (set -eo pipefail), daher hier kein eigenes "set".
: "${FLUTTER_VERSION:?FLUTTER_VERSION fehlt}"
base="https://storage.googleapis.com/flutter_infra_release/releases"

case "$(uname -s)" in
  Linux)
    root="${CI_PROJECT_DIR:-$PWD}/.cache/flutter"
    archive="stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    ;;
  Darwin)
    root="$HOME/.flutter-sdks"
    if [ "$(uname -m)" = "arm64" ]; then
      archive="stable/macos/flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
    else
      archive="stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"
    fi
    ;;
  *) echo "Nicht unterstütztes System: $(uname -s)"; exit 1 ;;
esac

sdk="$root/$FLUTTER_VERSION/flutter"
if [ ! -x "$sdk/bin/flutter" ]; then
  echo "Lade Flutter $FLUTTER_VERSION …"
  rm -rf "$root/$FLUTTER_VERSION"
  mkdir -p "$root/$FLUTTER_VERSION"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/flutter.archive" "$base/$archive"
  case "$archive" in
    *.tar.xz) tar -xJf "$tmp/flutter.archive" -C "$root/$FLUTTER_VERSION" ;;
    *.zip)    unzip -q "$tmp/flutter.archive" -d "$root/$FLUTTER_VERSION" ;;
  esac
  rm -rf "$tmp"
  # Andere Versionen im Cache aufräumen
  find "$root" -mindepth 1 -maxdepth 1 -type d ! -name "$FLUTTER_VERSION" -exec rm -rf {} + || true
fi

# Das SDK ist ein Git-Checkout; im Container gehört es oft einem anderen Benutzer.
git config --global --add safe.directory '*' >/dev/null 2>&1 || true

export PATH="$sdk/bin:$sdk/bin/cache/dart-sdk/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter config --no-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true
# Firebase kommt über CocoaPods; SPM zusätzlich führt zu "redefinition of module 'FirebaseCore'".
flutter config --no-enable-swift-package-manager >/dev/null 2>&1 || true
flutter --version

