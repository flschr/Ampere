//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

extension BTLocalization {
    enum StatusItem {
        static let unknown = NSLocalizedString(
            "Battery Toolkit status unavailable",
            comment: "Menu bar tooltip when the current power state cannot be read"
        )

        static let paused = NSLocalizedString(
            "Battery Toolkit is paused",
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
