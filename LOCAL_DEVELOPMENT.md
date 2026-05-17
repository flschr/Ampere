# Local Development

This fork is configured for local development with Rene Fischer's Apple
Development certificate.

## Bundle IDs

- App: `app.justasimple.ampere`
- XPC service: `app.justasimple.ampere.service`
- Login item: `app.justasimple.ampere.autostart`
- Privileged daemon: `app.justasimple.ampere.daemon`
- Privileged daemon Mach service:
  `H2FNY8B779.app.justasimple.ampere.daemon`

## Product Naming

The user-facing app name is `Ampere`. The main app target builds
`Ampere.app`, and the generated bundle name, display name, and executable name
are `Ampere`.

The Xcode project, scheme, bundle identifiers, helper identifiers, XPC service
identifier, and privileged daemon identifier use Ampere naming. Internal `BT*`
symbols remain unchanged because they are implementation symbols, not product
identity.

## Signing

- Development team: `H2FNY8B779`
- Development signing certificate:
  `Apple Development: rene@gaehn.org (UD9FDHGUAH)`

The Common Name is intentionally the certificate CN, while the team and Mach
service prefix use the Apple team identifier.

## Build

Open `Ampere.xcodeproj` in Xcode and build the `Ampere`
scheme.

From Terminal:

```sh
xcodebuild -project "Ampere.xcodeproj" \
  -scheme "Ampere" \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

The local Debug app is written to Xcode DerivedData, for example:

```text
~/Library/Developer/Xcode/DerivedData/Ampere-*/Build/Products/Debug/Ampere.app
```

Use Debug builds for local installation while signing with `Apple Development`.
Development-signed Release builds carry the `get-task-allow` entitlement, but
the Release daemon rejects clients with that entitlement as part of its XPC
hardening.

## Install For Local Testing

Copy the built `Ampere.app` to `/Applications`, then open it from
there. macOS will ask you to approve the background service before the
privileged daemon can run.

## Uninstall Local Build

Run `uninstall.sh` from this repository, then remove the app from
`/Applications`.
