//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal struct BTBatteryState: Equatable, Sendable {
    let enabled: Bool
    let powerDisabled: Bool
    let connected: Bool
    let chargingDisabled: Bool
    let batteryPercent: Int
    let progress: BTStateInfo.ChargingProgress
    let chargingMode: BTStateInfo.ChargingMode
    let maxCharge: Int
    let thermallyLimited: Bool
    let capabilities: BTPowerCapabilities

    init(
        enabled: Bool,
        powerDisabled: Bool = false,
        connected: Bool = false,
        chargingDisabled: Bool = false,
        batteryPercent: Int = 100,
        progress: BTStateInfo.ChargingProgress = .full,
        chargingMode: BTStateInfo.ChargingMode = .standard,
        maxCharge: Int = Int(BTSettingsInfo.Defaults.maxCharge),
        thermallyLimited: Bool = false,
        capabilities: BTPowerCapabilities = .legacy
    ) {
        self.enabled = enabled
        self.powerDisabled = powerDisabled
        self.connected = connected
        self.chargingDisabled = chargingDisabled
        self.batteryPercent = batteryPercent
        self.progress = progress
        self.chargingMode = chargingMode
        self.maxCharge = maxCharge
        self.thermallyLimited = thermallyLimited
        self.capabilities = capabilities
    }

    var usesPowerAdapter: Bool {
        self.enabled && self.connected && !self.powerDisabled
    }

    init(payload: [String: NSObject & Sendable]) throws {
        guard
            let enabled = (payload[BTStateInfo.Keys.enabled] as? NSNumber)?
                .boolValue
        else {
            throw BTError.malformedData
        }

        guard enabled else {
            self.init(enabled: false)
            return
        }

        guard
            let powerDisabled =
                (payload[BTStateInfo.Keys.powerDisabled] as? NSNumber)?
                    .boolValue,
            let connected = (payload[BTStateInfo.Keys.connected] as? NSNumber)?
                .boolValue,
            let chargingDisabled =
                (payload[BTStateInfo.Keys.chargingDisabled] as? NSNumber)?
                    .boolValue,
            let batteryPercent =
                (payload[BTStateInfo.Keys.batteryPercent] as? NSNumber)?
                    .intValue,
            let progressValue =
                (payload[BTStateInfo.Keys.progress] as? NSNumber)?
                    .uint8Value,
            let progress = BTStateInfo.ChargingProgress(rawValue: progressValue),
            let chargingModeValue =
                (payload[BTStateInfo.Keys.chargingMode] as? NSNumber)?
                    .uint8Value,
            let chargingMode =
                BTStateInfo.ChargingMode(rawValue: chargingModeValue),
            let maxCharge = (payload[BTStateInfo.Keys.maxCharge] as? NSNumber)?
                .intValue
        else {
            throw BTError.malformedData
        }
        let thermallyLimited =
            (payload[BTStateInfo.Keys.thermallyLimited] as? NSNumber)?
                .boolValue ?? false
        let capabilities = try BTPowerCapabilities(payload: payload)

        self.init(
            enabled: enabled,
            powerDisabled: powerDisabled,
            connected: connected,
            chargingDisabled: chargingDisabled,
            batteryPercent: batteryPercent,
            progress: progress,
            chargingMode: chargingMode,
            maxCharge: maxCharge,
            thermallyLimited: thermallyLimited,
            capabilities: capabilities
        )
    }

    var payload: [String: NSObject & Sendable] {
        guard self.enabled else {
            return [BTStateInfo.Keys.enabled: NSNumber(value: false)]
        }

        var payload: [String: NSObject & Sendable] = [
            BTStateInfo.Keys.enabled: NSNumber(value: self.enabled),
            BTStateInfo.Keys.powerDisabled: NSNumber(
                value: self.powerDisabled
            ),
            BTStateInfo.Keys.connected: NSNumber(value: self.connected),
            BTStateInfo.Keys.chargingDisabled: NSNumber(
                value: self.chargingDisabled
            ),
            BTStateInfo.Keys.batteryPercent: NSNumber(
                value: self.batteryPercent
            ),
            BTStateInfo.Keys.progress: NSNumber(
                value: self.progress.rawValue
            ),
            BTStateInfo.Keys.chargingMode: NSNumber(
                value: self.chargingMode.rawValue
            ),
            BTStateInfo.Keys.maxCharge: NSNumber(value: self.maxCharge),
            BTStateInfo.Keys.thermallyLimited: NSNumber(
                value: self.thermallyLimited
            ),
        ]
        payload.merge(self.capabilities.payload) { current, _ in current }
        return payload
    }
}

internal struct BTBatterySettings: Equatable, Sendable {
    let minCharge: Int
    let maxCharge: Int
    let adapterSleep: Bool
    let magSafeSync: Bool?
    let lowPowerModeThreshold: Int
    let capabilities: BTPowerCapabilities

    init(
        minCharge: Int,
        maxCharge: Int,
        adapterSleep: Bool,
        magSafeSync: Bool?,
        lowPowerModeThreshold: Int = Int(BTSettingsInfo.Defaults.lowPowerModeThreshold),
        capabilities: BTPowerCapabilities = .legacy
    ) throws {
        guard BTSettingsInfo.chargeLimitsValid(
            minCharge: minCharge,
            maxCharge: maxCharge
        ), BTSettingsInfo.lowPowerModeThresholdValid(lowPowerModeThreshold) else {
            throw BTError.malformedData
        }

        self.minCharge = minCharge
        self.maxCharge = maxCharge
        self.adapterSleep = adapterSleep
        self.magSafeSync = magSafeSync
        self.lowPowerModeThreshold = lowPowerModeThreshold
        self.capabilities = capabilities
    }

    init(payload: [String: NSObject & Sendable]) throws {
        guard
            let minCharge = (payload[BTSettingsInfo.Keys.minCharge] as? NSNumber)?
                .intValue,
            let maxCharge = (payload[BTSettingsInfo.Keys.maxCharge] as? NSNumber)?
                .intValue,
            let adapterSleep =
                (payload[BTSettingsInfo.Keys.adapterSleep] as? NSNumber)?
                    .boolValue
        else {
            throw BTError.malformedData
        }

        let magSafeSync =
            (payload[BTSettingsInfo.Keys.magSafeSync] as? NSNumber)?
                .boolValue
        let lowPowerModeThreshold: Int
        if let storedThreshold = payload[BTSettingsInfo.Keys.lowPowerModeThreshold] {
            guard let number = storedThreshold as? NSNumber else {
                throw BTError.malformedData
            }
            lowPowerModeThreshold = number.intValue
        } else {
            lowPowerModeThreshold = Int(BTSettingsInfo.Defaults.lowPowerModeThreshold)
        }
        let capabilities = try BTPowerCapabilities(payload: payload)
        try self.init(
            minCharge: minCharge,
            maxCharge: maxCharge,
            adapterSleep: adapterSleep,
            magSafeSync: magSafeSync,
            lowPowerModeThreshold: lowPowerModeThreshold,
            capabilities: capabilities
        )
    }

    var payload: [String: NSObject & Sendable] {
        var payload: [String: NSObject & Sendable] = [
            BTSettingsInfo.Keys.minCharge: NSNumber(value: self.minCharge),
            BTSettingsInfo.Keys.maxCharge: NSNumber(value: self.maxCharge),
            BTSettingsInfo.Keys.adapterSleep: NSNumber(
                value: self.adapterSleep
            ),
            BTSettingsInfo.Keys.lowPowerModeThreshold: NSNumber(
                value: self.lowPowerModeThreshold
            ),
        ]

        if let magSafeSync {
            payload[BTSettingsInfo.Keys.magSafeSync] = NSNumber(
                value: magSafeSync
            )
        }

        payload.merge(self.capabilities.payload) { current, _ in current }

        return payload
    }
}
