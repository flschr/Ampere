//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum Commands {
        static let unknownState = NSLocalizedString(
            "Unknown State",
            comment: "Menu status indicating the current charging state is unknown"
        )

        static let paused = NSLocalizedString(
            "Ampere Paused",
            comment: "Menu status indicating Ampere background activity is paused"
        )

        static let runningOnBattery = NSLocalizedString(
            "Running on Battery",
            comment: "Menu status indicating the Mac is running from battery"
        )

        static let usingPowerAdapter = NSLocalizedString(
            "Using Power Adapter",
            comment: "Menu status indicating the Mac is using the power adapter"
        )

        static func chargingUntil(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charging to %d%%",
                    comment: "Menu status indicating charging will stop at the configured charge limit"
                ),
                maxCharge
            )
        }

        static let chargingToFull = NSLocalizedString(
            "Charging to 100%",
            comment: "Menu status indicating charging to full battery"
        )

        static func holdingCharge(minCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charging paused until %d%%",
                    comment: "Menu status indicating charging is paused until battery drops below the minimum limit"
                ),
                minCharge
            )
        }

        static let chargingPausedHotBattery = NSLocalizedString(
            "Charging paused: battery too warm",
            comment: "Menu status indicating charging is paused because the battery is too warm"
        )

        static func waitingToCharge(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Waiting to charge to %d%%",
                    comment: "Menu status indicating charging will start later and stop at the configured charge limit"
                ),
                maxCharge
            )
        }

        static let waitingToChargeFull = NSLocalizedString(
            "Waiting to charge to 100%",
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

        static let usePowerAdapter = NSLocalizedString(
            "Use Power Adapter",
            comment: "Menu command to toggle whether the Mac uses the power adapter"
        )

        static let lowPowerMode = NSLocalizedString(
            "Low Power Mode",
            comment: "Menu command to toggle macOS Low Power Mode"
        )

        static func untilEmpty(duration: String) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "%@ until empty",
                    comment: "Menu status showing time remaining until the battery is empty"
                ),
                duration
            )
        }

        static func untilCharge(percent: Int, duration: String) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "%@ until %d%%",
                    comment: "Menu status showing time remaining until a battery percentage is reached"
                ),
                duration,
                percent
            )
        }

        static func approximateRemainingTime(_ title: String) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "approx. %@",
                    comment: "Menu status showing that a remaining time value is approximate"
                ),
                title
            )
        }
    }
}
