//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum StatusItem {
        static let unknown = NSLocalizedString(
            "Ampere status unavailable",
            comment: "Menu bar tooltip when the current power state cannot be read"
        )

        static let paused = NSLocalizedString(
            "Ampere is paused",
            comment: "Menu bar tooltip when background activity is paused"
        )

        static let adapterDisabled = NSLocalizedString(
            "Power adapter disabled, running on battery",
            comment: "Menu bar tooltip when the power adapter is disabled"
        )

        static let charging = NSLocalizedString(
            "Charging",
            comment: "Menu bar tooltip when charging is active"
        )

        static func batteryLevel(percent: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Battery: %d %%",
                    comment: "Menu status indicating the current battery level"
                ),
                percent
            )
        }

        static let chargingToFull = NSLocalizedString(
            "Charging to 100 %",
            comment: "Menu bar tooltip when charging to full battery"
        )

        static func chargingUntil(maxCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Charging to %d %%",
                    comment: "Menu bar tooltip when charging will stop at the configured charge limit"
                ),
                maxCharge
            )
        }

        static let holdingUnknown = NSLocalizedString(
            "Holding charge",
            comment: "Menu bar tooltip when charging is paused"
        )

        static let holdingHotBattery = NSLocalizedString(
            "Charging paused: battery too warm",
            comment: "Menu bar tooltip when charging is paused because the battery is too warm"
        )

        static func holding(minCharge: Int) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "Holding charge, resumes below %d %%",
                    comment: "Menu bar tooltip when charging is paused until the battery drops below the minimum limit"
                ),
                minCharge
            )
        }
    }
}
