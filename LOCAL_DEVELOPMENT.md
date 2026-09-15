# Local Development

This repository is configured for local development with the project signing
settings in Xcode.

## Bundle IDs

- App: `app.justasimple.ampere`
- XPC service: `app.justasimple.ampere.service`
- Login item: `app.justasimple.ampere.autostart`
- Privileged daemon: `app.justasimple.ampere.daemon`
- Privileged daemon Mach service:
  `<Apple Team ID>.app.justasimple.ampere.daemon`

## Product Naming

The user-facing app name is `Ampere`. The main app target builds
`Ampere.app`, and the generated bundle name, display name, and executable name
are `Ampere`.

The Xcode project, scheme, bundle identifiers, helper identifiers, XPC service
identifier, and privileged daemon identifier use Ampere naming. Internal `BT*`
symbols remain unchanged because they are implementation symbols, not product
identity.

## Signing

- Select a local Apple development team in Xcode.
- Use an `Apple Development` certificate for Debug builds.

The daemon, app, and XPC validation use the Apple team identifier for trusted
local development builds. If you change the team identifier, keep the daemon
Mach service name and signing settings in sync.

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

## Menu Charge Status Copy

The menu header describes the current power source first. Detail lines explain
what Ampere is waiting for or enforcing:

- When the power adapter supplies the Mac and charging is paused by the charge
  limit, show that the battery is not actively charging or discharging and that
  the configured charge limit is active. Do not claim the battery is held at the
  exact limit unless the current battery level is part of that message.
- When the Mac runs from battery above the lower charge threshold, describe the
  threshold that must be crossed before charging resumes.
- When the Mac runs from battery at or below the lower charge threshold, do not
  mention the threshold again. The missing condition is either connecting a
  power adapter or enabling power adapter use.
- Without a connected power adapter, charge request menu items can be visible
  for context, but must be disabled. Canceling an already pending charge request
  remains enabled.

## Install For Local Testing

Copy the built `Ampere.app` to `/Applications`, then open it from
there. macOS will ask you to approve the background service before the
privileged daemon can run.

## Uninstall Local Build

Run `uninstall.sh` from this repository, then remove the app from
`/Applications`.
