//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum Settings {
        static let lowPowerModeThreshold = NSLocalizedString(
            "Low Power Mode on battery at or below:",
            comment: "Battery percentage threshold for automatic Low Power Mode"
        )

        static let lowPowerModeOffHint = NSLocalizedString(
            "0% turns this automation off.",
            comment: "Explains the off position of the automatic Low Power Mode slider"
        )

        enum About {
            static let infoButtonAccessibilityLabel = NSLocalizedString(
                "About Ampere",
                comment: "Settings footer info button accessibility label"
            )

            static let versionFormat = NSLocalizedString(
                "Version %@",
                comment: "About screen version format"
            )

            static let sourceBuild = NSLocalizedString(
                "Unofficial Build",
                comment: "About screen label for builds that are not official signed releases"
            )

            static let officialBuild = NSLocalizedString(
                "Official Build",
                comment: "About screen label for signed official builds"
            )

            static let website = NSLocalizedString(
                "Website",
                comment: "About screen button to open the app website"
            )

            static let privacy = NSLocalizedString(
                "Privacy",
                comment: "About screen button to open the privacy policy"
            )

            static let licenses = NSLocalizedString(
                "Licenses",
                comment: "About screen link to open the licenses sheet"
            )

            static let checkForUpdates = NSLocalizedString(
                "Check for Updates…",
                comment: "About screen button to check for app updates"
            )

            static let licensesTitle = NSLocalizedString(
                "Licenses",
                comment: "Licenses sheet title"
            )

            static let licenseSummary = NSLocalizedString(
                "Ampere includes Battery Toolkit components. The BSD 3-Clause License and attribution are shown below.",
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

            static let updateUnavailableMessage = NSLocalizedString(
                "Updates are not configured for this build.",
                comment: "Update check error when Sparkle is not configured"
            )

            static let updateUnavailableInfo = NSLocalizedString(
                "Install an official release build or configure the Sparkle appcast URL and public EdDSA key for this build.",
                comment: "Update check error details when Sparkle is not configured"
            )

            static let sourceBuildUpdateUnavailableMessage =
                NSLocalizedString(
                    "Official updates are not available for unofficial builds.",
                    comment: "Update check error for unofficial builds"
                )

            static let sourceBuildUpdateUnavailableInfo = NSLocalizedString(
                "Build Ampere from the latest source or install an official release build to use automatic updates.",
                comment: "Update check error details for unofficial builds"
            )
        }

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

        static let uninstallAmpere = NSLocalizedString(
            "Uninstall Ampere…",
            comment: "Settings button to remove the background service, delete app data, and move the app to the Trash"
        )
    }
}
