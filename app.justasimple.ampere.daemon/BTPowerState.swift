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
    private static var adapterSleepDisabled = false

    static func initState() {
        self.chargingSleepDisabled = false
        self.adapterSleepDisabled = false

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
        if powerDisabled {
            //
            // Sleep must be disabled when external power is disabled.
            //
            self.disableAdapterSleep()
        }

        if SMCComm.MagSafe.supported {
            self.syncMagSafeState()
        }
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
        if powerDisabled != self.powerDisabled {
            self.powerDisabled = powerDisabled

            self.applyPowerAdapterSleepEffect(powerDisabled: powerDisabled)
        }

        if BTChargeController.capabilities.magSafeSync && BTSettings.magSafeSync {
            self.syncMagSafeState()
        }
    }

    static func getPercentRemaining() -> (UInt8, Bool, Bool) {
        return IOPSPrivate.GetPercentRemaining() ?? (100, false, false)
    }

    static func adapterSleepSettingToggled() {
        guard BTChargeController.capabilities.adapterControl else {
            return
        }
        //
        // If power is disabled, toggle sleep.
        //
        guard self.powerDisabled else {
            return
        }

        self.applyPowerAdapterSleepEffect(powerDisabled: true)
    }

    static func syncMagSafeState() {
        guard SMCComm.MagSafe.supported else {
            return
        }

        let target: UInt8 = BTPowerEvents.chargingMode == .toFull ?
            100 : BTSettings.maxCharge
        let state = BTMagSafeIndicatorState.resolve(
            mode: BTChargeController.capabilities.chargeControlMode,
            syncEnabled: BTSettings.magSafeSync,
            adapterDisabled: self.powerDisabled,
            externalPower: IOPSPrivate.DrawingUnlimitedPower(),
            battery: BTPowerEvents.hasPercentUpdates ?
                IOPSPrivate.GetPercentRemaining() : nil,
            target: target,
            directChargingDisabled: self.chargingDisabled
        )

        switch state {
        case .system:
            _ = SMCComm.MagSafe.setSystem()
        case .off:
            _ = SMCComm.MagSafe.setOff()
        case .amber:
            _ = SMCComm.MagSafe.setOrange()
        case .green:
            _ = SMCComm.MagSafe.setGreen()
        }
    }

    static func magSafeSyncSettingToggled() {
        guard BTChargeController.capabilities.magSafeSync else {
            return
        }
        self.syncMagSafeState()
    }

    static func disableCharging(percent: UInt8) -> Bool {
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

        if BTSettings.magSafeSync {
            BTPowerState.syncMagSafeState()
        }

        self.restoreChargingSleep()

        return true
    }

    static func enableCharging(
        percent: UInt8,
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

        if BTSettings.magSafeSync {
            BTPowerState.syncMagSafeState()
        }

        return true
    }

    static func disablePowerAdapter() -> Bool {
        guard BTChargeController.capabilities.adapterControl else {
            return false
        }
        guard !self.powerDisabled else {
            return true
        }

        self.disableAdapterSleep()

        let success = SMCComm.Power.disablePowerAdapter()
        guard success else {
            os_log("Failed to disable power adapter")
            self.restoreAdapterSleep()
            return false
        }

        if BTSettings.magSafeSync {
            _ = SMCComm.MagSafe.setOff()
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

        if BTSettings.magSafeSync {
            BTPowerState.syncMagSafeState()
        }

        self.restoreAdapterSleep()

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

    private static func disableAdapterSleep() {
        self.applyPowerAdapterSleepEffect(powerDisabled: true)
    }

    private static func restoreAdapterSleep() {
        self.applyPowerAdapterSleepEffect(powerDisabled: false)
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

    private static func applyPowerAdapterSleepEffect(powerDisabled: Bool) {
        switch BTPowerEventStateMachine.powerAdapterSleepEffect(
            powerDisabled: powerDisabled,
            adapterSleep: BTSettings.adapterSleep
        ) {
        case .disableSleep:
            self.disablePowerAdapterSleep()
        case .restoreSleep:
            self.restorePowerAdapterSleep()
        case .none:
            break
        }
    }

    private static func disablePowerAdapterSleep() {
        guard !self.adapterSleepDisabled else {
            return
        }

        GlobalSleep.disable()
        self.adapterSleepDisabled = true
    }

    private static func restorePowerAdapterSleep() {
        guard self.adapterSleepDisabled else {
            return
        }

        GlobalSleep.restore()
        self.adapterSleepDisabled = false
    }
}
