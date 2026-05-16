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
        chargingMode: BTStateInfo.ChargingMode
    ) -> Bool {
        return chargingMode == .standard
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
