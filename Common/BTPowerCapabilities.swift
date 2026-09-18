//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTChargeControlMode: UInt8, Sendable {
    case legacySMC = 0
    case firmwareSMC = 1
    case systemManaged = 2
}

internal struct BTPowerCapabilities: Equatable, Sendable {
    enum Keys {
        static let chargeControlMode = "ChargeControlMode"
        static let adapterControl = "AdapterControl"
        static let directChargingControl = "DirectChargingControl"
        static let customChargeRange = "CustomChargeRange"
        static let magSafeSync = "MagSafeSyncSupported"
        static let minimumMaxCharge = "MinimumMaxCharge"
        static let maxChargeStep = "MaxChargeStep"
    }

    let chargeControlMode: BTChargeControlMode
    let adapterControl: Bool
    let directChargingControl: Bool
    let customChargeRange: Bool
    let minimumMaxCharge: Int
    let maxChargeStep: Int

    private init(
        chargeControlMode: BTChargeControlMode,
        adapterControl: Bool,
        directChargingControl: Bool,
        customChargeRange: Bool,
        minimumMaxCharge: Int,
        maxChargeStep: Int
    ) {
        self.chargeControlMode = chargeControlMode
        self.adapterControl = adapterControl
        self.directChargingControl = directChargingControl
        self.customChargeRange = customChargeRange
        self.minimumMaxCharge = minimumMaxCharge
        self.maxChargeStep = maxChargeStep
    }

    static let legacy: Self = .init(
        chargeControlMode: .legacySMC,
        adapterControl: true,
        directChargingControl: true,
        customChargeRange: true,
        minimumMaxCharge: Int(BTSettingsInfo.Bounds.maxChargeMin),
        maxChargeStep: 1
    )

    static func legacy(adapterControl: Bool) -> Self {
        Self(
            chargeControlMode: .legacySMC,
            adapterControl: adapterControl,
            directChargingControl: true,
            customChargeRange: true,
            minimumMaxCharge: Int(BTSettingsInfo.Bounds.maxChargeMin),
            maxChargeStep: 1
        )
    }

    static func systemManaged(
        adapterControl: Bool,
        availableLimits: [UInt8]
    ) -> Self? {
        let limits = Array(Set(availableLimits)).sorted()
        guard let minimum = limits.first,
              minimum >= BTSettingsInfo.Bounds.maxChargeMin,
              limits.last == 100
        else {
            return nil
        }

        let differences = zip(limits.dropFirst(), limits).map { newer, older in
            Int(newer) - Int(older)
        }
        let step = differences.first ?? 1
        guard step > 0, differences.allSatisfy({ $0 == step }) else {
            return nil
        }

        return Self(
            chargeControlMode: .systemManaged,
            adapterControl: adapterControl,
            directChargingControl: false,
            customChargeRange: false,
            minimumMaxCharge: Int(minimum),
            maxChargeStep: Int(step)
        )
    }

    static func firmwareManaged(adapterControl: Bool) -> Self {
        Self(
            chargeControlMode: .firmwareSMC,
            adapterControl: adapterControl,
            directChargingControl: false,
            customChargeRange: true,
            minimumMaxCharge: Int(BTSettingsInfo.Bounds.maxChargeMin),
            maxChargeStep: 1
        )
    }

    init(payload: [String: NSObject & Sendable]) throws {
        guard let rawMode = (payload[Keys.chargeControlMode] as? NSNumber)?.uint8Value else {
            self = .legacy
            return
        }

        guard
            let mode = BTChargeControlMode(rawValue: rawMode),
            let adapterControl = (payload[Keys.adapterControl] as? NSNumber)?.boolValue,
            let directChargingControl =
                (payload[Keys.directChargingControl] as? NSNumber)?.boolValue,
            let customChargeRange =
                (payload[Keys.customChargeRange] as? NSNumber)?.boolValue,
            let minimumMaxCharge =
                (payload[Keys.minimumMaxCharge] as? NSNumber)?.intValue,
            let maxChargeStep = (payload[Keys.maxChargeStep] as? NSNumber)?.intValue,
            minimumMaxCharge >= Int(BTSettingsInfo.Bounds.maxChargeMin),
            minimumMaxCharge <= 100,
            maxChargeStep > 0,
            (100 - minimumMaxCharge) % maxChargeStep == 0,
            Self.modeIsConsistent(
                mode: mode,
                directChargingControl: directChargingControl,
                customChargeRange: customChargeRange
            )
        else {
            throw BTError.malformedData
        }

        self.init(
            chargeControlMode: mode,
            adapterControl: adapterControl,
            directChargingControl: directChargingControl,
            customChargeRange: customChargeRange,
            minimumMaxCharge: minimumMaxCharge,
            maxChargeStep: maxChargeStep
        )
    }

    var payload: [String: NSObject & Sendable] {
        [
            Keys.chargeControlMode: NSNumber(value: self.chargeControlMode.rawValue),
            Keys.adapterControl: NSNumber(value: self.adapterControl),
            Keys.directChargingControl: NSNumber(value: self.directChargingControl),
            Keys.customChargeRange: NSNumber(value: self.customChargeRange),
            // Older clients require this field, but LED override is retired.
            Keys.magSafeSync: NSNumber(value: false),
            Keys.minimumMaxCharge: NSNumber(value: self.minimumMaxCharge),
            Keys.maxChargeStep: NSNumber(value: self.maxChargeStep),
        ]
    }

    func supports(maxCharge: Int) -> Bool {
        guard maxCharge >= self.minimumMaxCharge, maxCharge <= 100 else {
            return false
        }

        return (maxCharge - self.minimumMaxCharge) % self.maxChargeStep == 0
    }

    func nearestSupported(maxCharge: Int) -> Int {
        let clamped = min(max(maxCharge, self.minimumMaxCharge), 100)
        let offset = clamped - self.minimumMaxCharge
        let roundedSteps = Int((Double(offset) / Double(self.maxChargeStep)).rounded())
        return min(self.minimumMaxCharge + roundedSteps * self.maxChargeStep, 100)
    }

    private static func modeIsConsistent(
        mode: BTChargeControlMode,
        directChargingControl: Bool,
        customChargeRange: Bool
    ) -> Bool {
        switch mode {
        case .legacySMC:
            return directChargingControl && customChargeRange
        case .firmwareSMC:
            return !directChargingControl && customChargeRange
        case .systemManaged:
            return !directChargingControl && !customChargeRange
        }
    }
}
