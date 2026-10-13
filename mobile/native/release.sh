#!/bin/bash
# Nahraje nový build do TestFlightu: zvýší číslo buildu, přegeneruje projekt,
# udělá archiv a pošle ho do App Store Connect.
#
#   ./release.sh                 nový build → TestFlight
#   ./release.sh --archive-only  jen archiv (bez čísla buildu +1 a bez nahrání)
#
# Vyžaduje v Xcode přihlášený placený Apple ID (Settings → Accounts).
set -euo pipefail
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
cd "$(dirname "$0")"

ARCHIVE_ONLY=0
[ "${1:-}" = "--archive-only" ] && ARCHIVE_ONLY=1

if [ "$ARCHIVE_ONLY" = 0 ]; then
  echo $(( $(cat BUILD_NUMBER) + 1 )) > BUILD_NUMBER
fi
BUILD=$(cat BUILD_NUMBER)
echo "▶ Build číslo $BUILD"

ruby gen_project.rb

ARCHIVE="/tmp/SkolaNaTaliri-$BUILD.xcarchive"
rm -rf "$ARCHIVE"
echo "▶ Archivuji…"
xcodebuild -project SkolaNaTaliri.xcodeproj -scheme SkolaNaTaliri -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" -allowProvisioningUpdates archive \
  > /tmp/skola-archive.log 2>&1 || { grep -E "error:" /tmp/skola-archive.log | sort -u; echo "✗ Archiv selhal (log: /tmp/skola-archive.log)"; exit 1; }
echo "✓ Archiv hotový: $ARCHIVE"

if [ "$ARCHIVE_ONLY" = 1 ]; then exit 0; fi

echo "▶ Nahrávám do App Store Connect…"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist ExportOptions.plist \
  -exportPath "/tmp/skola-export-$BUILD" -allowProvisioningUpdates \
  > /tmp/skola-export.log 2>&1 || { tail -15 /tmp/skola-export.log; echo "✗ Nahrání selhalo (log: /tmp/skola-export.log)"; exit 1; }
echo "✓ Nahráno (build $BUILD). Zpracování v TestFlightu trvá obvykle 5–15 minut."
echo "  Nezapomeň commitnout BUILD_NUMBER: git add mobile/native/BUILD_NUMBER"
