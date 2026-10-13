#!/bin/bash
# Builds a signed, notarized release of Figma Responder in release/:
#   Figma-Responder-<version>-arm64.dmg   download for new installs
#   Figma-Responder-<version>-arm64.zip   what in-app updates download
#   latest-mac.yml                        the update feed
# Upload all three to the GitHub release for v<version>.
#
# Notarization runs here with the "notarytool" keychain profile rather than
# inside electron-builder, whose notarytool call can't read that profile.
set -euo pipefail

cd "$(dirname "$0")/.."

SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Santiago Alonso Alexandre (QAMM2A6WRQ)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notarytool}"
VERSION="$(node -p "require('./package.json').version")"
APP="release/mac-arm64/Figma AI Responder.app"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/figma-responder-release.XXXXXX")"

npm run build

# 1. Signed app only.
npx electron-builder --mac --arm64 --dir -c.mac.notarize=false --publish never

# 2. Notarize and staple the app itself, so the zip used for updates carries the ticket.
ditto -c -k --keepParent "$APP" "$WORK/app.zip"
xcrun notarytool submit "$WORK/app.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"

# 3. DMG, update zip and latest-mac.yml from the stapled app, without re-signing it.
npx electron-builder --mac dmg zip --arm64 --prepackaged "$APP" \
  -c.mac.identity=null -c.mac.notarize=false --publish never

# 4. Sign, notarize and staple the DMG.
DMG="release/Figma-Responder-$VERSION-arm64.dmg"
codesign --sign "$SIGN_IDENTITY" --timestamp "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"

echo "Upload to v$VERSION: $DMG, release/Figma-Responder-$VERSION-arm64.zip, release/latest-mac.yml"
