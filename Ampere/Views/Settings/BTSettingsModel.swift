//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal struct BTChargeLimitDraft: Equatable, Sendable {
    private(set) var minCharge: UInt8
    private(set) var maxCharge: UInt8

    init(
        minCharge: UInt8 = BTSettingsInfo.Defaults.minCharge,
        maxCharge: UInt8 = BTSettingsInfo.Defaults.maxCharge
    ) {
        self.minCharge = minCharge
        self.maxCharge = maxCharge
    }

    mutating func setMinCharge(_ value: Int) {
        let clamped = Self.clamp(
            value,
            lowerBound: Int(BTSettingsInfo.Bounds.minChargeMin)
        )
        self.minCharge = UInt8(clamped)
        if self.maxCharge < self.minCharge {
            self.maxCharge = self.minCharge
        }
    }

    mutating func setMaxCharge(_ value: Int) {
        let clamped = Self.clamp(
            value,
            lowerBound: Int(BTSettingsInfo.Bounds.maxChargeMin)
        )
        self.maxCharge = UInt8(clamped)
        if self.minCharge > self.maxCharge {
            self.minCharge = self.maxCharge
        }
    }

    private static func clamp(_ value: Int, lowerBound: Int) -> Int {
        min(max(value, lowerBound), 100)
    }
}

internal enum BTSettingsPayloadFactory {
    static func make(
        minCharge: Int,
        maxCharge: Int,
        adapterSleep: Bool,
        magSafeSync: Bool?,
        lowPowerModeThreshold: Int = Int(BTSettingsInfo.Defaults.lowPowerModeThreshold),
        capabilities: BTPowerCapabilities = .legacy
    ) throws -> [String: NSObject & Sendable] {
        try BTBatterySettings(
            minCharge: minCharge,
            maxCharge: maxCharge,
            adapterSleep: adapterSleep,
            magSafeSync: magSafeSync,
            lowPowerModeThreshold: lowPowerModeThreshold,
            capabilities: capabilities
        ).payload
    }

    static func changed(
        _ newSettings: [String: NSObject & Sendable],
        from currentSettings: [String: NSObject & Sendable]?
    ) -> Bool {
        !(newSettings as NSDictionary).isEqual(to: currentSettings)
    }
}
