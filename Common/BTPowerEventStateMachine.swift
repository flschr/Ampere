//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTPowerEventStateMachine {
    enum ChargingEffect: Equatable {
        case none
        case enableCharging
        case disableCharging
    }

    enum SleepEffect: Equatable {
        case none
        case disableSleep
        case restoreSleep
    }

    enum WakeEffect: Equatable {
        case disableSleep
        case refreshPowerState
        case handleChargeHysteresis
        case handleLimitedPower
        case restoreSleep
    }

    enum ThermalEffect: Equatable {
        case none
        case pauseCharging
        case resumeCharging
    }

    enum Thermal {
        static let pauseTemperatureCelsius = 40.0
        static let resumeTemperatureCelsius = 38.0
    }

    static func hysteresisEffect(
        percent: UInt8,
        minCharge: UInt8,
        maxCharge: UInt8,
        chargingMode: BTStateInfo.ChargingMode
    ) -> ChargingEffect {
        if percent >= maxCharge {
            if chargingMode != .toFull || percent >= 100 {
                return .disableCharging
            }
        } else if percent < minCharge {
            return .enableCharging
        }

        return .none
    }

    static func pendingModeEffect(
        percent: UInt8,
        chargingMode: BTStateInfo.ChargingMode,
        maxCharge: UInt8
    ) -> ChargingEffect {
        switch chargingMode {
        case .toLimit:
            return percent < maxCharge ? .enableCharging : .none
        case .toFull:
            return percent < 100 ? .enableCharging : .none
        case .standard:
            return .none
        }
    }

    static func belowLimitModeEffect(percent: UInt8, limit: UInt8) -> ChargingEffect {
        return percent < limit ? .enableCharging : .none
    }

    static func disconnectedRecoveryEffect(
        percent: UInt8,
        minCharge: UInt8,
        chargingMode: BTStateInfo.ChargingMode
    ) -> ChargingEffect {
        guard chargingMode == .standard else {
            return .none
        }

        return percent < minCharge ? .enableCharging : .none
    }

    static func shouldMonitorDisconnectedBattery(
        chargingMode: BTStateInfo.ChargingMode,
        lowPowerModeThreshold: UInt8 = 0
    ) -> Bool {
        return chargingMode == .standard || lowPowerModeThreshold > 0
    }

    static func shouldEnableLowPowerMode(
        percent: UInt8,
        threshold: UInt8,
        drawingUnlimitedPower: Bool
    ) -> Bool {
        return threshold > 0 && !drawingUnlimitedPower && percent <= threshold
    }

    static func thermalEffect(
        temperatureCelsius: Double?,
        thermallyLimited: Bool,
        chargingDisabled: Bool,
        percent: UInt8,
        minCharge: UInt8,
        chargingMode: BTStateInfo.ChargingMode,
        pauseTemperatureCelsius: Double = Thermal.pauseTemperatureCelsius,
        resumeTemperatureCelsius: Double = Thermal.resumeTemperatureCelsius
    ) -> ThermalEffect {
        guard let temperatureCelsius else {
            return thermallyLimited ? .resumeCharging : .none
        }

        if thermallyLimited {
            return temperatureCelsius <= resumeTemperatureCelsius ?
                .resumeCharging :
                .none
        }

        let chargingExpected = !chargingDisabled ||
            chargingMode != .standard ||
            percent < minCharge
        guard chargingExpected,
              temperatureCelsius >= pauseTemperatureCelsius else {
            return .none
        }

        return .pauseCharging
    }

    static func thermalRecoveryEffect(
        percent: UInt8,
        maxCharge: UInt8,
        chargingMode: BTStateInfo.ChargingMode
    ) -> ChargingEffect {
        switch chargingMode {
        case .toFull:
            return percent < 100 ? .enableCharging : .none
        case .standard, .toLimit:
            return percent < maxCharge ? .enableCharging : .none
        }
    }

    static func chargingSleepEffect(chargingDisabled: Bool) -> SleepEffect {
        return chargingDisabled ? .restoreSleep : .disableSleep
    }

    static func powerAdapterSleepEffect(
        powerDisabled: Bool,
        adapterSleep: Bool
    ) -> SleepEffect {
        guard !adapterSleep else {
            return .none
        }

        return powerDisabled ? .disableSleep : .restoreSleep
    }

    static func wakeFromSleepEffects(
        percentHandlerRegistered: Bool
    ) -> [WakeEffect] {
        var effects: [WakeEffect] = [
            .disableSleep,
            .refreshPowerState
        ]

        if percentHandlerRegistered {
            effects.append(.handleChargeHysteresis)
        }

        effects.append(.handleLimitedPower)
        effects.append(.restoreSleep)

        return effects
    }
}
