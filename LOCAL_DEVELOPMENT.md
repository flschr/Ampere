# Local Development

This fork is configured for local development with Rene Fischer's Apple
Development certificate.

## Bundle IDs

- App: `app.justasimple.battertoolkit`
- XPC service: `app.justasimple.battertoolkit.service`
- Login item: `app.justasimple.battertoolkit.autostart`
- Privileged daemon: `app.justasimple.battertoolkit.daemon`
- Privileged daemon Mach service:
  `H2FNY8B779.app.justasimple.battertoolkit.daemon`

## Signing

- Development team: `H2FNY8B779`
- Development signing certificate:
  `Apple Development: rene@gaehn.org (UD9FDHGUAH)`

The Common Name is intentionally the certificate CN, while the team and Mach
service prefix use the Apple team identifier.

## Build

Open `Battery Toolkit.xcodeproj` in Xcode and build the `Battery Toolkit`
scheme.

From Terminal:

```sh
xcodebuild -project "Battery Toolkit.xcodeproj" \
  -scheme "Battery Toolkit" \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

The local Debug app is written to Xcode DerivedData, for example:

```text
~/Library/Developer/Xcode/DerivedData/Battery_Toolkit-*/Build/Products/Debug/Battery Toolkit.app
```

Use Debug builds for local installation while signing with `Apple Development`.
Development-signed Release builds carry the `get-task-allow` entitlement, but
the Release daemon rejects clients with that entitlement as part of its XPC
hardening.

## Install For Local Testing

Copy the built `Battery Toolkit.app` to `/Applications`, then open it from
there. macOS will ask you to approve the background service before the
privileged daemon can run.

## Uninstall Local Build

Run `uninstall.sh` from this repository, then remove the app from
`/Applications`.
