//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLocalization {
    enum Prompts {
        static let ok = NSLocalizedString(
            "OK",
            comment: "Prompt button to acknowledge a situation"
        )

        static let approve = NSLocalizedString(
            "Approve",
            comment: "Prompt button to approve an action"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Prompt button to cancel an action"
        )

        static let retry = NSLocalizedString(
            "Retry",
            comment: "Prompt button to retry an action"
        )

        static let uninstall = NSLocalizedString(
            "Uninstall",
            comment: "Prompt button to uninstall the app"
        )

        static let quit = NSLocalizedString(
            "Quit",
            comment: "Prompt button to quit the app"
        )

        static let disableAndQuit = NSLocalizedString(
            "Disable and Quit",
            comment: "Prompt button to disable a core function and quit the app"
        )

        static let openSystemSettings = NSLocalizedString(
            "Open System Settings",
            comment: "Prompt button to open System Settings"
        )

        static let quitMessage = NSLocalizedString(
            "Quit Battery Toolkit?",
            comment: "Prompt caption asking whether to quit the app"
        )

        static let quitInfo = NSLocalizedString(
            "Battery Toolkit will continue to run in the background. To permanently suspend it, disable the background activity from the Battery Toolkit menu.",
            comment: "Prompt caption asking whether to quit the app"
        )

        static let quitInfoMacOS13 = NSLocalizedString(
            "To temporarily suspend it, disable the background activity in System Settings.",
            comment: "Prompt caption asking whether to quit the app"
        )

        static let unexpectedErrorMessage = NSLocalizedString(
            "An unexpected error has occured.",
            comment: "Prompt caption informing the user of an unexpected error"
        )

        static let notAuthorizedMessage = NSLocalizedString(
            "You do not have permission to perform this operation.",
            comment: "Prompt caption informing the user that they are not authorized to perform a specific operation"
        )

        enum Daemon {
            static let requiredInfo = NSLocalizedString(
                "To manage the power state of your Mac, Battery Toolkit needs to run in the background.",
                comment: "Prompt text explaining the requirement for background activity"
            )

            static let allowMessage = NSLocalizedString(
                "Allow background activity?",
                comment: "Prompt caption asking to allow background activity"
            )

            static let allowInfo = NSLocalizedString(
                "Do you want to approve the Battery Toolkit Login Item in System Settings?",
                comment: "Prompt text asking to approve background activity"
            )

            static let enableFailMessage = NSLocalizedString(
                "Failed to enable background activity.",
                comment: "Prompt caption informing of failure to enable background activity"
            )

            static let disableMessage = NSLocalizedString(
                "Disable background activity?",
                comment: "Prompt caption asking whether to disable background activity"
            )

            static let disableInfo = NSLocalizedString(
                "Do you want to disable background activity for Battery Toolkit?",
                comment: "Prompt text asking whether to disable background activity"
            )

            static let disableFailMessage = NSLocalizedString(
                "An error occurred disabling background activity.",
                comment: "Prompt caption informing of failure to disable background activity"
            )

            static let uninstallMessage = NSLocalizedString(
                "Uninstall Battery Toolkit?",
                comment: "Prompt caption asking whether to uninstall the app"
            )

            static let uninstallInfo = NSLocalizedString(
                "Battery Toolkit will remove the background service, disable automatic startup, delete its local settings, move the app to the Trash, and quit.",
                comment: "Prompt text explaining what uninstalling the app does"
            )

            static let uninstallFailMessage = NSLocalizedString(
                "An error occurred uninstalling Battery Toolkit.",
                comment: "Prompt caption informing of failure to uninstall the app"
            )

            static let commFailMessage = NSLocalizedString(
                "Failed to communicate with the background service.",
                comment: "Prompt caption informing the user that the app failed to communicate with its background service"
            )

            static let commFailInfo = NSLocalizedString(
                "Please restart your Mac and try again. If the problem persists, contact the developers.",
                comment: "Prompt text instructing the user to restart the machine and try again"
            )

            static let unsupportedMessage = NSLocalizedString(
                "Your Mac is not supported.",
                comment: "Prompt caption informing the user that the app does not support this machine"
            )

            static let unsupportedInfo = NSLocalizedString(
                "Battery Toolkit does not support managing the power state of your Mac. Background activity will be disabled.",
                comment: "Prompt text informing the user the app does not support this machine and that background activity will be disabled in response"
            )
        }
    }

    static let preferences = NSLocalizedString(
        "Preferences",
        comment: "Preferences for macOS 12 and below"
    )

    enum Commands {
        static func chargingUntil(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charging until %d %%",
                    comment: "Menu status indicating charging will stop at the configured charge limit"
                ),
                maxCharge
            )
        }

        static let chargingToFull = NSLocalizedString(
            "Charging to 100 %",
            comment: "Menu status indicating charging to full battery"
        )

        static func holdingCharge(minCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Holding charge; resumes below %d %%",
                    comment: "Menu status indicating charging is paused until battery drops below the minimum limit"
                ),
                minCharge
            )
        }

        static func waitingToCharge(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Waiting; will charge to %d %%",
                    comment: "Menu status indicating charging will start later and stop at the configured charge limit"
                ),
                maxCharge
            )
        }

        static let waitingToChargeFull = NSLocalizedString(
            "Waiting; will charge to 100 %",
            comment: "Menu status indicating charging will start later and charge to full battery"
        )

        static func chargeToLimitNow(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charge to %d %% Now",
                    comment: "Menu command to start charging immediately up to the configured charge limit"
                ),
                maxCharge
            )
        }

        static func requestChargingToLimitNow(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Request Charging to %d %% Now",
                    comment: "Menu command to request charging up to the configured charge limit"
                ),
                maxCharge
            )
        }
    }

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
    }
}
