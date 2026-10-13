#!/bin/bash
# Update test for Figma Responder's in-app updates (electron-updater), before
# a release. Builds and notarizes the current version and a throwaway 99.0.0,
# points a test copy's app-update.yml at a local feed, lets it download the
# update, quits it and checks it was replaced with a valid, notarized 99.0.0.
# Afterwards trash the work folder it prints and the caches and settings the
# test copy creates (~/Library/Caches/*figma-ai-responder*,
# ~/Library/Application Support/figma-ai-responder) if they weren't there before.
set -euo pipefail
cd ~/Projects/figma-responder
ID="Developer ID Application: Santiago Alonso Alexandre (QAMM2A6WRQ)"
APPNAME="Figma AI Responder"
BID="com.san.figma-ai-responder"
W="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/fr-update-test.XXXXXX")" && pwd -P)"
PORT="$(python3 -I -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
fail() { echo "FAIL: $1"; exit 1; }
notarize() {  # $1 = app path
  ditto -c -k --keepParent "$1" "$W/notary.zip"
  xcrun notarytool submit "$W/notary.zip" --keychain-profile notarytool --wait | grep 'status:' | tail -1
  xcrun stapler staple -q "$1"
}
echo "work: $W"
lsappinfo list | grep -q "bundleID=\"$BID\"" && fail "Figma Responder is running; quit it first"

node node_modules/electron/install.js
npm run build >/dev/null

echo "==> Version N (current)"
npx electron-builder --mac --arm64 --dir -c.mac.notarize=false --publish never -c.directories.output="$W/n" >/dev/null
notarize "$W/n/mac-arm64/$APPNAME.app"

echo "==> Throwaway 99.0.0"
npx electron-builder --mac --arm64 --dir -c.mac.notarize=false --publish never \
  -c.extraMetadata.version=99.0.0 -c.directories.output="$W/next" >/dev/null
notarize "$W/next/mac-arm64/$APPNAME.app"
npx electron-builder --mac zip --arm64 --prepackaged "$W/next/mac-arm64/$APPNAME.app" \
  -c.mac.identity=null -c.mac.notarize=false -c.extraMetadata.version=99.0.0 --publish never \
  -c.directories.output="$W/feed" >/dev/null
ls "$W/feed"; grep '^version' "$W/feed/latest-mac.yml"

echo "==> Test copy of N pointed at the local feed"
mkdir -p "$W/install"
ditto "$W/n/mac-arm64/$APPNAME.app" "$W/install/$APPNAME.app"
INST="$W/install/$APPNAME.app"
CACHE_LINE="$(grep '^updaterCacheDirName' "$INST/Contents/Resources/app-update.yml" || true)"
printf 'provider: generic\nurl: http://127.0.0.1:%s\n%s\n' "$PORT" "$CACHE_LINE" > "$INST/Contents/Resources/app-update.yml"
codesign -f -o runtime --timestamp --preserve-metadata=entitlements,requirements,flags -s "$ID" "$INST"
codesign --verify --deep --strict "$INST"
VERSION_N="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INST/Contents/Info.plist")"

python3 -I -m http.server "$PORT" --bind 127.0.0.1 --directory "$W/feed" > "$W/server.log" 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null; pgrep -f "$W/install" | xargs kill -TERM 2>/dev/null; true' EXIT
open -n "$INST"
echo "==> Waiting for the download (up to 3 minutes)"
for _ in $(seq 1 180); do grep -q 'GET /.*\.zip' "$W/server.log" && break; sleep 1; done
cat "$W/server.log"
grep -q 'GET /latest-mac.yml' "$W/server.log" || fail "never read latest-mac.yml"
grep -q 'GET /.*\.zip' "$W/server.log" || fail "read the feed but didn't download the zip"
sleep 25  # let Squirrel verify and stage the update
PID="$(pgrep -f "$INST/Contents/MacOS/" | head -1)"
osascript -e "tell application id \"$BID\" to quit" >/dev/null 2>&1 || kill -TERM "$PID"
for _ in $(seq 1 30); do kill -0 "$PID" 2>/dev/null || break; sleep 1; done
for _ in $(seq 1 60); do
  V="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INST/Contents/Info.plist" 2>/dev/null || true)"
  [ "$V" = "99.0.0" ] && break; sleep 1
done
[ "$V" = "99.0.0" ] || fail "not replaced (still $V)"
codesign --verify --deep --strict "$INST" || fail "bad signature after update"
spctl -a -vv "$INST" 2>&1 | grep -q 'source=Notarized Developer ID' || fail "Gatekeeper rejects the updated app"
echo "PASS: Figma Responder updated itself from $VERSION_N to 99.0.0; signature and Gatekeeper checks pass"
