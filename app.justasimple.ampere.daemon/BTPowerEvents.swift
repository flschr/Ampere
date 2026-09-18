//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Dispatch
import Foundation
import IOKit.ps
import os.log

@MainActor
internal enum BTPowerEvents {
    static var updating = false

    private(set) static var chargingMode = BTStateInfo.ChargingMode.standard
    private(set) static var unlimitedPower = false
    private(set) static var thermallyLimited = false

    private static var powerCreated = false
    private static var percentCreated = false
    private static var thermalTimer: DispatchSourceTimer? = nil
    private static let thermalCheckInterval: TimeInterval = 120

    static func start() throws {
        BTLowPowerModeAutomation.reset()
        let smcSuccess = SMCComm.start()
        guard smcSuccess else {
            throw BTError.unknown
        }

        let supported = BTChargeController.start()
        guard supported else {
            os_log("Machine is unsupported")
            SMCComm.stop()
            throw BTError.unsupported
        }

        BTSettings.normalizeForCapabilities()
        guard BTChargeController.applyStandardLimit(
            minCharge: BTSettings.minCharge,
            maxCharge: BTSettings.maxCharge
        ) else {
            os_log("Failed to apply the configured charge limit")
            _ = BTChargeController.restoreOriginalState()
            SMCComm.stop()
            throw BTError.unknown
        }

        let registerSuccess = self.registerLimitedPowerHandler()
        guard registerSuccess else {
            self.restoreState()
            SMCComm.stop()
            throw BTError.unknown
        }
    }

    private static func restoreState() {
        //
        // If the daemon is being updated, don't restore the default platform
        // power state.
        //
        if !self.updating || !BTChargeController.usesLegacyControl {
            self.restoreDefaults()
        }

        GlobalSleep.forceRestore()
        //
        // Don't free remaining resources, as we will exit anyway.
        //
    }

    static func exit() {
        guard self.powerCreated else {
            return
        }

        self.restoreState()
    }

    static func stop() {
        assert(self.powerCreated)

        self.unregisterLimitedPowerHandler()
        self.unregisterPercentChangedHandler()
        self.stopThermalTimer()
        self.thermallyLimited = false
        self.restoreState()
        SMCComm.stop()
    }

    static func wakeFromSleep() {
        assert(self.powerCreated)

        for effect in BTPowerEventStateMachine.wakeFromSleepEffects(
            percentHandlerRegistered: self.percentCreated
        ) {
            self.apply(wakeEffect: effect)
        }
    }

    static func settingsChanged() -> Bool {
        if !BTChargeController.usesLegacyControl {
            self.chargingMode = .standard
            let applied = BTChargeController.applyStandardLimit(
                minCharge: BTSettings.minCharge,
                maxCharge: BTSettings.maxCharge
            )
            guard applied else {
                return false
            }
            BTPowerState.refreshState()
        }

        guard self.percentCreated else {
            return true
        }

        _ = self.handlePercentChanged()
        return true
    }

    static func lowPowerModeThresholdChanged() {
        BTLowPowerModeAutomation.reset()
        guard self.powerCreated, !self.unlimitedPower else {
            return
        }

        if BTSettings.lowPowerModeThreshold > 0 {
            if !self.registerPercentChangedHandler() {
                os_log("Failed to monitor battery for Low Power Mode")
            }
        } else if BTChargeController.usesLegacyControl &&
                    !BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                        chargingMode: self.chargingMode
                    ) {
            self.unregisterPercentChangedHandler()
        }
    }

    static func chargeToLimit() -> Bool {
        if !BTChargeController.usesLegacyControl {
            self.chargingMode = .standard
            return BTChargeController.applyStandardLimit(
                minCharge: BTSettings.minCharge,
                maxCharge: BTSettings.maxCharge
            )
        }

        self.chargingMode = .toLimit
        if self.unlimitedPower {
            BTLowPowerModeAutomation.disableForPowerAdapter()
        }
        return self.enableBelowLimitMode(limit: BTSettings.maxCharge)
    }

    static func enablePowerAdapter() -> Bool {
        let success = BTPowerState.enablePowerAdapter(force: true)
        guard success else {
            return false
        }

        BTLowPowerModeAutomation.disableForPowerAdapter()
        self.unlimitedPower = self.drawingUnlimitedPower()

        return true
    }

    static func disableCharging(percent: UInt8) -> Bool {
        guard BTChargeController.capabilities.directChargingControl else {
            return false
        }
        self.chargingMode = .standard
        self.thermallyLimited = false
        return BTPowerState.disableCharging(percent: percent)
    }

    static func disableCharging() -> Bool {
        let (percent, _, _) = BTPowerState.getPercentRemaining()
        return self.disableCharging(percent: percent)
    }

    static func chargeToFull() -> Bool {
        self.chargingMode = .toFull
        if self.unlimitedPower {
            BTLowPowerModeAutomation.disableForPowerAdapter()
        }
        if !BTChargeController.usesLegacyControl {
            return BTChargeController.requestFullCharge()
        }
        return self.enableBelowLimitMode(limit: 100)
    }

    static func getChargingProgress() -> BTStateInfo.ChargingProgress {
        guard let (percent, _, _) = IOPSPrivate.GetPercentRemaining() else {
            return .full
        }

        if percent < BTSettings.maxCharge {
            return .belowMax
        }

        if percent < 100 {
            return .belowFull
        }

        return .full
    }

    private static func limitedPowerHandler(token _: Int32) {
        //
        // An unlucky dispatching order of LimitedPower and PercentChanged
        // events may cause this constraint to actually be violated.
        //
        guard self.powerCreated else {
            return
        }

        self.handleLimitedPower()
    }

    private static func percentChangeHandler(token _: Int32) {
        //
        // An unlucky dispatching order of LimitedPower and PercentChanged
        // events may cause this constraint to actually be violated.
        //
        guard self.percentCreated else {
            return
        }

        _ = self.handlePercentChanged()
    }

    private static func registerLimitedPowerHandler() -> Bool {
        guard !self.powerCreated else {
            return true
        }
        //
        // The charging state has no default value when starting the daemon.
        // We do not want to default to enabled, because this may cause many
        // micro-charges when continuously updating the daemon.
        // We do not want to default to disabled, because this may cause
        // micro-charges when starting the service after a fresh boot (e.g.,
        // on Apple Silicon devices, where the SMC state is reset to
        // defaults when resetting the platform).
        //
        // Initialize the sleep state based on the current platform state.
        //
        BTPowerState.initState()

        self.powerCreated = BTDispatcher.registerLimitedPowerNotification { token in
            self.limitedPowerHandler(token: token)
        }
        guard self.powerCreated else {
            return false
        }

        self.handleLimitedPower()

        return true
    }

    private static func unregisterLimitedPowerHandler() {
        BTDispatcher.unregisterLimitedPowerNotification()
        self.powerCreated = false
    }

    private static func registerPercentChangedHandler() -> Bool {
        if !self.percentCreated {
            self.percentCreated = BTDispatcher.registerPercentChangeNotification { token in
                self.percentChangeHandler(token: token)
            }
            guard self.percentCreated else {
                return false
            }
        }

        let percent = self.handlePercentChanged()
        guard BTChargeController.usesLegacyControl else {
            return true
        }
        guard self.unlimitedPower, !self.thermallyLimited else {
            return true
        }
        //
        // In case charging to limit or full were requested while the device
        // was on battery, enable it now if appropriate.
        //
        switch BTPowerEventStateMachine.pendingModeEffect(
            percent: percent,
            chargingMode: self.chargingMode,
            maxCharge: BTSettings.maxCharge
        ) {
        case .enableCharging:
            _ = BTPowerState.enableCharging(percent: percent)
        case .disableCharging, .none:
            break
        }

        self.updateThermalTimer()
        return true
    }

    private static func unregisterPercentChangedHandler() {
        guard self.percentCreated else {
            return
        }

        BTDispatcher.unregisterPercentChangeNotification()
        self.percentCreated = false
    }

    private static func handlePercentChanged() -> UInt8 {
        assert(self.percentCreated)

        guard let (percent, _, _) = IOPSPrivate.GetPercentRemaining() else {
            return 100
        }

        if !BTChargeController.usesLegacyControl {
            self.handleManagedPercent(percent: percent)
        } else if self.unlimitedPower {
            self.handleConnectedPower(percent: percent)
        } else {
            self.handleDisconnectedRecovery(percent: percent)
        }

        BTLowPowerModeAutomation.apply(
            percent: percent,
            threshold: BTSettings.lowPowerModeThreshold,
            drawingUnlimitedPower: self.drawingUnlimitedPower()
        )

        return percent
    }

    private static func handleManagedPercent(percent: UInt8) {
        BTPowerState.refreshState()
        guard self.chargingMode == .toFull, percent >= 100 else {
            return
        }

        self.chargingMode = .standard
        if !BTChargeController.applyStandardLimit(
            minCharge: BTSettings.minCharge,
            maxCharge: BTSettings.maxCharge
        ) {
            os_log("Failed to restore the configured charge limit")
        }
        BTPowerState.refreshState()
    }

    private static func handleConnectedPower(percent: UInt8) {
        if !self.handleThermalProtection(percent: percent) {
            self.handleChargeHysteresis(percent: percent)
        }

        self.updateThermalTimer()
    }

    @discardableResult
    private static func handleThermalProtection(percent: UInt8) -> Bool {
        switch BTPowerEventStateMachine.thermalEffect(
            temperatureCelsius: IOPSPrivate.GetBatteryTemperatureCelsius(),
            thermallyLimited: self.thermallyLimited,
            chargingDisabled: BTPowerState.isChargingDisabled(),
            percent: percent,
            minCharge: BTSettings.minCharge,
            chargingMode: self.chargingMode
        ) {
        case .pauseCharging:
            self.thermallyLimited = true
            _ = BTPowerState.disableCharging(percent: percent)
            return true
        case .resumeCharging:
            self.thermallyLimited = false
            self.resumeChargingAfterThermalLimit(percent: percent)
            return false
        case .none:
            return self.thermallyLimited
        }
    }

    private static func resumeChargingAfterThermalLimit(percent: UInt8) {
        switch BTPowerEventStateMachine.thermalRecoveryEffect(
            percent: percent,
            maxCharge: BTSettings.maxCharge,
            chargingMode: self.chargingMode
        ) {
        case .enableCharging:
            _ = BTPowerState.enableCharging(percent: percent)
        case .disableCharging, .none:
            break
        }
    }

    private static func handleChargeHysteresis(percent: UInt8) {
        switch BTPowerEventStateMachine.hysteresisEffect(
            percent: percent,
            minCharge: BTSettings.minCharge,
            maxCharge: BTSettings.maxCharge,
            chargingMode: self.chargingMode
        ) {
        case .disableCharging:
            //
            // Charging modes are reset once we disable charging.
            //
            _ = BTPowerEvents.disableCharging(percent: percent)
        case .enableCharging:
            _ = BTPowerState.enableCharging(percent: percent)
        case .none:
            if !BTPowerState.isChargingDisabled() {
                _ = BTPowerState.enableCharging(percent: percent)
            }
            break
        }
    }

    private static func handleDisconnectedRecovery(percent: UInt8) {
        guard BTPowerEventStateMachine.disconnectedRecoveryEffect(
            percent: percent,
            minCharge: BTSettings.minCharge,
            chargingMode: self.chargingMode
        ) == .enableCharging else {
            return
        }

        os_log("Forcing disconnected below-min charging recovery")
        _ = self.enableChargingForCurrentPowerState(percent: percent, force: true)
    }

    private static func drawingUnlimitedPower() -> Bool {
        //
        // macOS may falsely report drawing unlimited power when the power
        // adapter is actually disabled.
        //
        return !BTPowerState.isPowerAdapterDisabled() &&
            IOPSPrivate.DrawingUnlimitedPower()
    }

    private static func enableChargingForCurrentPowerState(
        percent: UInt8,
        force: Bool = false
    ) -> Bool {
        let adapterEnabled = BTPowerState.enablePowerAdapter(force: force)
        guard adapterEnabled else {
            return false
        }

        self.unlimitedPower = self.drawingUnlimitedPower()
        if self.unlimitedPower {
            BTLowPowerModeAutomation.disableForPowerAdapter()
            guard !self.handleThermalProtection(percent: percent) else {
                self.updateThermalTimer()
                return true
            }
        }

        let chargingEnabled = BTPowerState.enableCharging(
            percent: percent,
            disablesSleep: self.unlimitedPower,
            force: force
        )
        if self.unlimitedPower {
            _ = BTPowerState.enableCharging(percent: percent, force: force)
        }
        self.updateThermalTimer()

        return chargingEnabled
    }

    private static func handleLimitedPowerGuarded() {
        assert(self.powerCreated)

        self.unlimitedPower = self.drawingUnlimitedPower()

        if !BTChargeController.usesLegacyControl {
            self.thermallyLimited = false
            if self.unlimitedPower {
                BTLowPowerModeAutomation.disableForPowerAdapter()
            } else {
                BTLowPowerModeAutomation.normalizeForBatteryPower()
            }
            if !self.registerPercentChangedHandler() {
                os_log("Failed to register percent changed handler")
            }
            BTPowerState.refreshState()
            return
        }

        if self.unlimitedPower {
            BTLowPowerModeAutomation.disableForPowerAdapter()
            let success = self.registerPercentChangedHandler()
            if !success {
                os_log("Failed to register percent changed handler")
                self.restoreDefaults()
            }
            self.updateThermalTimer()
        } else {
            self.stopThermalTimer()
            self.thermallyLimited = false
            BTLowPowerModeAutomation.normalizeForBatteryPower()
            let (percent, _, _) = BTPowerState.getPercentRemaining()
            if BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: percent,
                minCharge: BTSettings.minCharge,
                chargingMode: self.chargingMode
            ) == .enableCharging {
                let success = self.registerPercentChangedHandler()
                if !success {
                    os_log("Failed to register percent changed handler")
                    self.restoreDefaults()
                }
                return
            }

            //
            // Disable charging to not have micro-charges happening when
            // connecting to power.
            //
            _ = BTPowerEvents.disableCharging()
            if BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingMode: self.chargingMode,
                lowPowerModeThreshold: BTSettings.lowPowerModeThreshold
            ) {
                let success = self.registerPercentChangedHandler()
                if !success {
                    os_log("Failed to register percent changed handler")
                    self.restoreDefaults()
                }
            } else {
                self.unregisterPercentChangedHandler()
            }
        }
    }

    private static func handleLimitedPower() {
        //
        // Immediately disable sleep to not interrupt the setup phase.
        //
        GlobalSleep.disable()

        self.handleLimitedPowerGuarded()
        //
        // Restore sleep from the setup phase.
        //
        GlobalSleep.restore()
    }

    private static func apply(wakeEffect: BTPowerEventStateMachine.WakeEffect) {
        switch wakeEffect {
        case .disableSleep:
            //
            // Immediately disable sleep to not interrupt the setup phase.
            //
            GlobalSleep.disable()
        case .refreshPowerState:
            BTPowerState.refreshState()
        case .handleChargeHysteresis:
            _ = self.handlePercentChanged()
        case .handleLimitedPower:
            self.handleLimitedPowerGuarded()
        case .restoreSleep:
            //
            // Restore sleep from the setup phase.
            //
            GlobalSleep.restore()
        }
    }

    private static func restoreDefaults() {
        if BTSettings.magSafeSync {
            _ = SMCComm.MagSafe.setSystem()
        }

        if !BTChargeController.usesLegacyControl {
            if !BTChargeController.restoreOriginalState() {
                os_log("Failed to restore the original charge limit")
            }
            #if !DEBUG
                if BTChargeController.capabilities.adapterControl {
                    _ = BTPowerState.enablePowerAdapter()
                }
            #endif
            self.thermallyLimited = false
            return
        }

        //
        // Do not reset to defaults when debugging to not stress the batteries
        // of development machines.
        //
        #if !DEBUG
            let (percent, _, _) = BTPowerState.getPercentRemaining()
            _ = BTPowerState.enableCharging(percent: percent)
            _ = BTPowerState.enablePowerAdapter()
        #endif
        self.thermallyLimited = false
    }

    private static func enableBelowLimitMode(limit: UInt8) -> Bool {
        //
        // When the percent loop is inactive, there is no battery-level event
        // source to decide whether charging should start immediately. The
        // request will be handled once power or percent events are observed.
        //
        guard self.percentCreated else {
            return true
        }

        guard let (percent, _, _) = IOPSPrivate.GetPercentRemaining() else {
            return false
        }

        if self.unlimitedPower, self.handleThermalProtection(percent: percent) {
            self.updateThermalTimer()
            return true
        }

        if BTPowerEventStateMachine.belowLimitModeEffect(
            percent: percent,
            limit: limit
        ) == .enableCharging {
            return self.enableChargingForCurrentPowerState(
                percent: percent,
                force: !self.unlimitedPower
            )
        }

        self.updateThermalTimer()
        return true
    }

    private static func updateThermalTimer() {
        let needsTimer = self.unlimitedPower &&
            (!BTPowerState.isChargingDisabled() || self.thermallyLimited)
        if needsTimer {
            self.startThermalTimer()
        } else {
            self.stopThermalTimer()
        }
    }

    private static func startThermalTimer() {
        guard self.thermalTimer == nil else {
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(
            deadline: .now() + self.thermalCheckInterval,
            repeating: self.thermalCheckInterval
        )
        timer.setEventHandler {
            Task { @MainActor in
                self.handleThermalTimer()
            }
        }
        timer.resume()
        self.thermalTimer = timer
    }

    private static func stopThermalTimer() {
        self.thermalTimer?.cancel()
        self.thermalTimer = nil
    }

    private static func handleThermalTimer() {
        guard self.powerCreated, self.unlimitedPower else {
            self.stopThermalTimer()
            return
        }

        let (percent, _, _) = BTPowerState.getPercentRemaining()
        self.handleConnectedPower(percent: percent)
    }
}
