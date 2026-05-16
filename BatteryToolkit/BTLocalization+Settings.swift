//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum Settings {
        enum Presets {
            static let everyday = NSLocalizedString(
                "Everyday",
                comment: "Charge preset for everyday battery use"
            )

            static let desk = NSLocalizedString(
                "Desk",
                comment: "Charge preset for mostly desk-bound battery use"
            )

            static let travel = NSLocalizedString(
                "Travel",
                comment: "Charge preset for travel battery use"
            )
        }

        static let preset = NSLocalizedString(
            "Preset:",
            comment: "Label for charge preset segmented control"
        )

        static let optimizedChargingWarning = NSLocalizedString(
            "macOS Optimized Battery Charging is on. Turn it off in Battery settings so Ampere can manage charging reliably.",
            comment: "Warning shown when macOS Optimized Battery Charging is enabled"
        )

        static let uninstall = NSLocalizedString(
            "Uninstall",
            comment: "Settings section title for removing the background service and app data"
        )

        static let uninstallInfo = NSLocalizedString(
            "Remove the background service, disable automatic startup, delete Ampere's local settings, and move the app to the Trash.",
            comment: "Settings description explaining what uninstalling the background service does"
        )

        static let uninstallBatteryToolkit = NSLocalizedString(
            "Uninstall Ampere…",
            comment: "Settings button to remove the background service, delete app data, and move the app to the Trash"
        )
    }
}
