//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

extension BTSettingsViewController {
    func configureMagSafe(settings: BTBatterySettings) {
        if settings.capabilities.chargeControlMode == .systemManaged {
            self.magSafeSyncSwitch.isHidden = true
            self.magSafeSyncSwitch.isEnabled = false
            self.magSafeSyncSwitch.state = .off
            self.magSafeSyncLabel.stringValue = Bundle.main.localizedString(
                forKey: "MagSafeManagedTitle",
                value: "macOS controls the MagSafe light",
                table: "Settings"
            )
            self.magSafeDescriptionTextField.stringValue =
                Bundle.main.localizedString(
                    forKey: "MagSafeManagedDescription",
                    value: "The light follows macOS charging and its charge limit. No separate Ampere control is needed.",
                    table: "Settings"
                )
            return
        }

        self.magSafeSyncLabel.stringValue = Bundle.main.localizedString(
            forKey: "47S-lH-kMQ.title",
            value: "Adapt MagSafe light to charge limit",
            table: "Settings"
        )
        self.magSafeDescriptionTextField.stringValue =
            Bundle.main.localizedString(
                forKey: "3Kk-Vy-Cgc.title",
                value: "Amber while charging or paused below the limit; green when the charge target is reached. No blinking. The light is off if the power adapter is disabled.",
                table: "Settings"
            )
        self.magSafeSyncSwitch.isHidden = false
        if let enabled = settings.magSafeSync {
            self.magSafeSyncSwitch.isEnabled = true
            self.magSafeSyncSwitch.state = enabled ? .on : .off
        } else {
            self.magSafeSyncSwitch.isEnabled = false
        }
    }
}
