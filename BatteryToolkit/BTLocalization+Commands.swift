//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum Commands {
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
    }
}
