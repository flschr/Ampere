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
            "macOS Optimized Battery Charging is on. Turn it off in Battery settings so Battery Toolkit can manage charging reliably.",
            comment: "Warning shown when macOS Optimized Battery Charging is enabled"
        )

        static let autostart = NSLocalizedString(
            "Open Battery Toolkit automatically when you log in to your Mac",
            comment: "Settings label for launching Battery Toolkit automatically on login"
        )

        static let menuBarExtraInfo = NSLocalizedString(
            "Display a menu bar extra to easily control the power state of your Mac. The background activity is independent from the application and is unaffected by this setting.",
            comment: "Settings description explaining the menu bar extra"
        )

        static let uninstall = NSLocalizedString(
            "Uninstall",
            comment: "Settings section title for removing the background service and app data"
        )

        static let uninstallInfo = NSLocalizedString(
            "Remove the background service, disable automatic startup, delete Battery Toolkit's local settings, and move the app to the Trash.",
            comment: "Settings description explaining what uninstalling the background service does"
        )

        static let uninstallBatteryToolkit = NSLocalizedString(
            "Uninstall Battery Toolkit…",
            comment: "Settings button to remove the background service, delete app data, and move the app to the Trash"
        )

        enum StatusItem {
            static let displayMode = NSLocalizedString(
                "Menu bar display:",
                comment: "Settings label for choosing how the menu bar item appears"
            )

            static let iconOnly = NSLocalizedString(
                "Icon only",
                comment: "Menu bar display mode showing only the battery icon"
            )

            static let iconAndPercent = NSLocalizedString(
                "Icon and percentage",
                comment: "Menu bar display mode showing the battery icon and charge percentage"
            )

            static let percentOnly = NSLocalizedString(
                "Percentage only",
                comment: "Menu bar display mode showing only the charge percentage"
            )

            static let hidden = NSLocalizedString(
                "Hidden",
                comment: "Menu bar display mode hiding the status item"
            )
        }
    }
}
