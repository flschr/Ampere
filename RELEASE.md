# Ampere Release and Updates

This project uses Sparkle 2 for direct macOS distribution outside the App Store.
Sparkle is the update authority for release builds; Homebrew is only an
installation channel.

## Sparkle Configuration

Release builds must provide these build settings:

```sh
BT_SPARKLE_FEED_URL=<public HTTPS URL for appcast.xml>
BT_SPARKLE_PUBLIC_ED_KEY=<public EdDSA key from Sparkle>
```

The private EdDSA key is a release secret. Do not commit it to the repository.
If either value is missing, Ampere keeps the updater disabled and the manual
update command explains that updates are not configured for the current build.

`BT_SPARKLE_FEED_URL` is not predefined by the app. Choose the final hosting
location before the first public Sparkle release. Good options are a static file
on the product site, GitHub Pages, or another HTTPS static host that can serve
both `appcast.xml` and the release artifacts reliably.

## Generate Sparkle Keys

Resolve the Swift package dependency once in Xcode, then run Sparkle's key tool
from the resolved package:

```sh
find ~/Library/Developer/Xcode/DerivedData \
  -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys' \
  -print
```

Run the located `generate_keys` binary, store the private key in the release
secret store, and copy the public key into `BT_SPARKLE_PUBLIC_ED_KEY` for
release builds.

## Build and Notarize

1. Increment both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
2. Build `Ampere.app` with a Developer ID Application certificate.
3. Archive the app as a ZIP or DMG release artifact.
4. Submit the artifact to Apple notarization with `xcrun notarytool`.
5. Staple the notarization ticket before publishing.

The embedded privileged daemon is updated by Ampere on next launch when its
code identity no longer matches the daemon bundled in the app. The existing
daemon `prepareUpdate` and `finishUpdate` commands preserve power state during
that helper replacement.

## Generate the Appcast

Place the signed and notarized release artifact in a release directory, then run
Sparkle's appcast generator from the resolved package:

```sh
find ~/Library/Developer/Xcode/DerivedData \
  -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast' \
  -print
```

Run the located `generate_appcast` binary against the release directory. The
resulting appcast must be uploaded to `BT_SPARKLE_FEED_URL`, and the artifact
URL in the appcast must be reachable over HTTPS.

## Local or Staging Appcast

For local testing, build an older signed app, install it in `/Applications`, and
serve an appcast that points to a newer signed artifact:

```sh
python3 -m http.server 8000 --directory /path/to/appcast-root
```

Then build Ampere with:

```sh
BT_SPARKLE_FEED_URL=http://127.0.0.1:8000/appcast.xml
BT_SPARKLE_PUBLIC_ED_KEY=<matching public key>
```

Use `Ampere > Check for Updates...` or the About screen's update link. Sparkle
should show its native update dialog when the appcast contains a newer
`CFBundleVersion`.

## Failure Cases to Verify

- Missing network: Sparkle shows the native connection failure.
- No update: Sparkle reports that Ampere is up to date.
- Invalid appcast or signature: Sparkle rejects the update.
- Unsigned or differently signed artifact: Sparkle refuses installation.
- Helper mismatch after app update: Ampere prompts for the daemon update path
  and finishes with the new bundled helper registered.

## Homebrew

Homebrew should not replace Sparkle. Once public releases use Sparkle, the Cask
should declare:

```ruby
auto_updates true
livecheck do
  url "<public HTTPS URL for appcast.xml>"
  strategy :sparkle
end
```

The existing archived Homebrew tap still refers to the old distribution.
Ampere needs either a maintained tap or a future submission to Homebrew Cask
once the public download and appcast URLs are stable.
