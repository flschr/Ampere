//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTPowerState {
    private static var chargingDisabled = false
    private static var chargingSleepDisabled = false
    private static var powerDisabled = false

    static func initState() {
        self.chargingSleepDisabled = false

        if BTChargeController.usesLegacyControl {
            let chargingDisabled = SMCComm.Power.isChargingDisabled()
            self.chargingDisabled = chargingDisabled
        } else {
            self.refreshManagedChargingState()
        }
        if BTChargeController.usesLegacyControl && !self.chargingDisabled {
            //
            // Sleep must always be disabled when charging is enabled.
            //
            self.disableChargingSleep()
        }

        let powerDisabled = BTChargeController.capabilities.adapterControl &&
            SMCComm.Power.isPowerAdapterDisabled()
        self.powerDisabled = powerDisabled
    }

    static func refreshState() {
        //
        // Refresh platform stated when waking from sleep, as events might not
        // fire.
        //
        let chargingDisabled: Bool
        if BTChargeController.usesLegacyControl {
            chargingDisabled = SMCComm.Power.isChargingDisabled()
        } else {
            self.refreshManagedChargingState()
            chargingDisabled = self.chargingDisabled
        }
        if chargingDisabled != self.chargingDisabled {
            self.chargingDisabled = chargingDisabled

            if BTChargeController.usesLegacyControl {
                self.applyChargingSleepEffect(
                    sleepEffect: BTPowerEventStateMachine.chargingSleepEffect(
                        chargingDisabled: chargingDisabled
                    )
                )
            }
        }

        let powerDisabled = BTChargeController.capabilities.adapterControl &&
            SMCComm.Power.isPowerAdapterDisabled()
        self.powerDisabled = powerDisabled
    }

    static func getPercentRemaining() -> (UInt8, Bool, Bool) {
        return IOPSPrivate.GetPercentRemaining() ?? (100, false, false)
    }

    static func disableCharging() -> Bool {
        guard BTChargeController.capabilities.directChargingControl else {
            return false
        }
        guard !self.chargingDisabled else {
            return true
        }

        let success = SMCComm.Power.disableCharging()
        guard success else {
            os_log("Failed to disable charging")
            return false
        }

        self.chargingDisabled = true

        self.restoreChargingSleep()

        return true
    }

    static func enableCharging(
        disablesSleep: Bool = true,
        force: Bool = false
    ) -> Bool {
        guard BTChargeController.capabilities.directChargingControl else {
            return false
        }
        guard force || self.chargingDisabled else {
            if disablesSleep {
                self.disableChargingSleep()
            }
            return true
        }

        let success = SMCComm.Power.enableCharging()
        if !success {
            os_log("Failed to enable charging")
            return false
        }

        if disablesSleep {
            self.disableChargingSleep()
        }

        self.chargingDisabled = false

        return true
    }
    static func disablePowerAdapter() -> Bool {
        guard BTChargeController.capabilities.adapterControl else {
            return false
        }
        guard !self.powerDisabled else {
            return true
        }

        let success = SMCComm.Power.disablePowerAdapter()
        guard success else {
            os_log("Failed to disable power adapter")
            return false
        }

        self.powerDisabled = true
        return true
    }

    static func enablePowerAdapter(force: Bool = false) -> Bool {
        guard BTChargeController.capabilities.adapterControl else {
            return true
        }
        guard force || self.powerDisabled else {
            return true
        }

        let success = SMCComm.Power.enablePowerAdapter()
        guard success else {
            os_log("Failed to enable power adapter")
            return false
        }

        self.powerDisabled = false

        return true
    }

    static func isChargingDisabled() -> Bool {
        return self.chargingDisabled
    }

    static func isPowerAdapterDisabled() -> Bool {
        return self.powerDisabled
    }

    private static func refreshManagedChargingState() {
        guard let (_, charging, fullyCharged) = IOPSPrivate.GetPercentRemaining()
        else {
            return
        }
        self.chargingDisabled = IOPSPrivate.DrawingUnlimitedPower() &&
            !charging && !fullyCharged
    }

    private static func disableChargingSleep() {
        guard !self.chargingSleepDisabled else {
            return
        }

        GlobalSleep.disable()
        self.chargingSleepDisabled = true
    }

    private static func restoreChargingSleep() {
        guard self.chargingSleepDisabled else {
            return
        }

        GlobalSleep.restore()
        self.chargingSleepDisabled = false
    }

    private static func applyChargingSleepEffect(
        sleepEffect: BTPowerEventStateMachine.SleepEffect
    ) {
        switch sleepEffect {
        case .disableSleep:
            self.disableChargingSleep()
        case .restoreSleep:
            self.restoreChargingSleep()
        case .none:
            break
        }
    }
}
