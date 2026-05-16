//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum Commands {
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
                    "Charging to %d %%",
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
                    "Holding charge, resumes below %d %%",
                    comment: "Menu status indicating charging is paused until battery drops below the minimum limit"
                ),
                minCharge
            )
        }

        static func waitingToCharge(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Waiting, will charge to %d %%",
                    comment: "Menu status indicating charging will start later and stop at the configured charge limit"
                ),
                maxCharge
            )
        }

        static let waitingToChargeFull = NSLocalizedString(
            "Waiting, will charge to 100 %",
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

        static let runOnBattery = NSLocalizedString(
            "Run on Battery",
            comment: "Menu command to disable the power adapter and run from battery"
        )

        static let usePowerAdapter = NSLocalizedString(
            "Use Power Adapter",
            comment: "Menu command to enable the power adapter"
        )

        static let lowPowerMode = NSLocalizedString(
            "Low Power Mode",
            comment: "Menu command to toggle macOS Low Power Mode"
        )

        static func untilEmpty(duration: String) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Until Empty: %@",
                    comment: "Menu status showing time remaining until the battery is empty"
                ),
                duration
            )
        }

        static func untilCharge(percent: Int, duration: String) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Until %d %%: %@",
                    comment: "Menu status showing time remaining until a battery percentage is reached"
                ),
                percent,
                duration
            )
        }
    }
}
