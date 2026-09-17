//
// Copyright (C) 2026 René Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTLowPowerModeAutomation {
    private static var triggered = false

    static func reset() {
        self.triggered = false
    }

    static func disableForPowerAdapter() {
        self.reset()
        do {
            let changed = try BTLowPowerMode.disableIfEnabled()
            if changed {
                os_log("Disabled Low Power Mode for power adapter")
            }
        } catch {
            os_log(
                "Failed to disable Low Power Mode for power adapter: \(error, privacy: .public)"
            )
        }
    }

    static func normalizeForBatteryPower() {
        do {
            let changed = try BTLowPowerMode.normalizeForBatteryPower()
            if changed {
                os_log("Normalized Low Power Mode for battery power")
            }
        } catch {
            os_log(
                "Failed to normalize Low Power Mode for battery power: \(error, privacy: .public)"
            )
        }
    }

    static func apply(
        percent: UInt8,
        threshold: UInt8,
        drawingUnlimitedPower: Bool
    ) {
        let shouldEnable = BTPowerEventStateMachine.shouldEnableLowPowerMode(
            percent: percent,
            threshold: threshold,
            drawingUnlimitedPower: drawingUnlimitedPower
        )
        guard shouldEnable else {
            self.reset()
            return
        }
        guard !self.triggered else {
            return
        }

        do {
            if try !BTLowPowerMode.isEnabled() {
                try BTLowPowerMode.setEnabled(true)
                os_log("Enabled Low Power Mode at configured battery threshold")
            }
            self.triggered = true
        } catch {
            os_log(
                "Failed to enable Low Power Mode automatically: \(error, privacy: .public)"
            )
        }
    }
}
