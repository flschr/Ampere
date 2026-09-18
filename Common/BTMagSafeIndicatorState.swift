//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

internal enum BTMagSafeIndicatorState: Equatable {
    case system
    case off
    case amber
    case green

    static func resolve(
        mode: BTChargeControlMode,
        syncEnabled: Bool,
        adapterDisabled: Bool,
        externalPower: Bool,
        battery: (percent: UInt8, charging: Bool, fullyCharged: Bool)?,
        target: UInt8,
        directChargingDisabled: Bool
    ) -> Self {
        guard mode != .systemManaged, syncEnabled else {
            return .system
        }

        if adapterDisabled {
            return .off
        }

        guard externalPower, let battery else {
            return .system
        }

        let charging = battery.charging &&
            !(mode == .legacySMC && directChargingDisabled)
        if charging {
            return .amber
        }

        // A full flag can still describe the previous limit after a request
        // to charge to 100%, so the active target decides when to show green.
        return battery.percent >= target ? .green : .amber
    }
}
