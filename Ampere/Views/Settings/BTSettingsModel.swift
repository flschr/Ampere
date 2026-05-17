//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTChargePreset: Int, CaseIterable, Sendable {
    case everyday
    case desk
    case travel

    var title: String {
        switch self {
        case .everyday:
            return BTLocalization.Settings.Presets.everyday
        case .desk:
            return BTLocalization.Settings.Presets.desk
        case .travel:
            return BTLocalization.Settings.Presets.travel
        }
    }

    var minCharge: Int {
        switch self {
        case .everyday:
            return 70
        case .desk:
            return 50
        case .travel:
            return 80
        }
    }

    var maxCharge: Int {
        switch self {
        case .everyday, .desk:
            return 80
        case .travel:
            return 90
        }
    }

    static func matching(minCharge: Int, maxCharge: Int) -> Self? {
        Self.allCases.first { preset in
            preset.minCharge == minCharge && preset.maxCharge == maxCharge
        }
    }
}

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

    var matchingPreset: BTChargePreset? {
        BTChargePreset.matching(
            minCharge: Int(self.minCharge),
            maxCharge: Int(self.maxCharge)
        )
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
        magSafeSync: Bool?
    ) throws -> [String: NSObject & Sendable] {
        try BTBatterySettings(
            minCharge: minCharge,
            maxCharge: maxCharge,
            adapterSleep: adapterSleep,
            magSafeSync: magSafeSync
        ).payload
    }

    static func changed(
        _ newSettings: [String: NSObject & Sendable],
        from currentSettings: [String: NSObject & Sendable]?
    ) -> Bool {
        !(newSettings as NSDictionary).isEqual(to: currentSettings)
    }
}
