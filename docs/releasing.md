# Releasing

1. Bump `version` in `package.json` (and the README version line).
2. Run `scripts/release.sh`. It builds and signs the app, notarizes and staples
   it, makes the DMG, the update zip and `latest-mac.yml` from that app, then
   notarizes and staples the DMG. It needs the Developer ID certificate and the
   `notarytool` keychain profile, with the login keychain unlocked.
3. Create the GitHub release `v<version>` and upload
   `release/Figma-Responder-<version>-arm64.dmg`,
   `release/Figma-Responder-<version>-arm64.zip` and `release/latest-mac.yml`.

In-app updates (electron-updater) read `latest-mac.yml` from the newest release
and download the zip in the background; the update installs when the app quits.
Checks only work once the repo is public. Copies older than the first release
with the updater have to be updated by hand once.
