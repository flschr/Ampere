//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum Settings {
        enum About {
            static let infoButtonAccessibilityLabel = NSLocalizedString(
                "About Ampere",
                comment: "Settings footer info button accessibility label"
            )

            static let versionBuildFormat = NSLocalizedString(
                "Version %@ (%@)",
                comment: "About screen version and build number format"
            )

            static let publisherFormat = NSLocalizedString(
                "Author/Publisher: %@",
                comment: "About screen author and publisher format"
            )

            static let website = NSLocalizedString(
                "Website",
                comment: "About screen button to open the app website"
            )

            static let privacy = NSLocalizedString(
                "Privacy",
                comment: "About screen button to open the privacy policy"
            )

            static let license = NSLocalizedString(
                "License",
                comment: "About screen button to open the license text"
            )

            static let attributionTitle = NSLocalizedString(
                "Attribution & Licenses",
                comment: "About screen license section title"
            )

            static let attributionSummary = NSLocalizedString(
                "Ampere is based on Battery Toolkit and includes components distributed under the BSD 3-Clause License.",
                comment: "About screen attribution summary"
            )

            static let licenseTitle = NSLocalizedString(
                "BSD 3-Clause License",
                comment: "License sheet title"
            )

            static let licenseSummary = NSLocalizedString(
                "The full license text is provided below for binary distribution.",
                comment: "License sheet explanatory text"
            )

            static let unknownValue = NSLocalizedString(
                "Unknown",
                comment: "About screen fallback for unavailable bundle values"
            )

            static let close = NSLocalizedString(
                "Close",
                comment: "About screen close button"
            )
        }

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
