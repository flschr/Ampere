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

        static let poweredByBattery = NSLocalizedString(
            "MacBook is powered by the battery",
            comment: "Menu status indicating the MacBook is powered by battery"
        )

        static let poweredByAdapter = NSLocalizedString(
            "MacBook is powered by the power adapter",
            comment: "Menu status indicating the MacBook is powered by the power adapter"
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

        static func chargingResumesBelow(minCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charging resumes below %d%%",
                    comment: "Menu detail indicating charging resumes after the battery drops below the minimum limit"
                ),
                minCharge
            )
        }

        static func chargingResumesBelowWhenAdapterConnected(
            minCharge: Int
        ) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charges again below %d%% when a power adapter is connected",
                    comment: "Menu detail indicating charging resumes below the minimum limit once a power adapter is connected"
                ),
                minCharge
            )
        }

        static let chargingWhenAdapterConnected = NSLocalizedString(
            "Charges when a power adapter is connected",
            comment: "Menu detail indicating charging can start once a power adapter is connected"
        )

        static let chargingWhenPowerAdapterUsed = NSLocalizedString(
            "Charges when the power adapter is used",
            comment: "Menu detail indicating charging can start once power adapter use is enabled"
        )

        static let batteryNotActivelyChargingOrDischarging = NSLocalizedString(
            "Battery is not actively charging or discharging",
            comment: "Menu detail indicating the battery is neither actively charging nor discharging"
        )

        static func chargeLimitActive(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charge limit %d%% is active",
                    comment: "Menu detail indicating the configured charge limit is active"
                ),
                maxCharge
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
                    "Charge to %d%% Now",
                    comment: "Menu command to start charging immediately up to the configured charge limit"
                ),
                maxCharge
            )
        }

        static func requestChargingToLimit(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Request Charging to %d%%",
                    comment: "Menu command to request charging up to the configured charge limit when charging cannot start immediately"
                ),
                maxCharge
            )
        }

        static let usePowerAdapter = NSLocalizedString(
            "Use Power Adapter Instead of Battery",
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
