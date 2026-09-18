//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTSettings {
    private(set) static var minCharge = BTSettingsInfo.Defaults.minCharge
    private(set) static var maxCharge = BTSettingsInfo.Defaults.maxCharge
    private(set) static var lowPowerModeThreshold =
        BTSettingsInfo.Defaults.lowPowerModeThreshold

    static func readDefaults() {
        // Retired controls must not survive an upgrade as hidden preferences.
        UserDefaults.standard.removeObject(forKey: BTSettingsInfo.Keys.adapterSleep)
        UserDefaults.standard.removeObject(forKey: BTSettingsInfo.Keys.magSafeSync)
        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        let storedThreshold = UserDefaults.standard.integer(
            forKey: BTSettingsInfo.Keys.lowPowerModeThreshold
        )
        self.lowPowerModeThreshold =
            BTSettingsInfo.lowPowerModeThresholdValid(storedThreshold) ?
                UInt8(storedThreshold) : BTSettingsInfo.Defaults.lowPowerModeThreshold

        let minCharge = UserDefaults.standard.integer(
            forKey: BTSettingsInfo.Keys.minCharge
        )
        let maxCharge = UserDefaults.standard.integer(
            forKey: BTSettingsInfo.Keys.maxCharge
        )
        guard
            BTSettingsInfo.chargeLimitsValid(
                minCharge: minCharge,
                maxCharge: maxCharge
            )
        else {
            os_log("Charge limits malformed, restore current values")
            self.writeDefaults()
            return
        }

        let limits = BTChargeController.normalizedLimits(
            minCharge: UInt8(minCharge),
            maxCharge: UInt8(maxCharge)
        )
        self.minCharge = limits.min
        self.maxCharge = limits.max
    }

    static func removeDefaults() {
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.adapterSleep
        )
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.magSafeSync
        )
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.minCharge
        )
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.maxCharge
        )
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.lowPowerModeThreshold
        )

        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    static func getSettings() -> [String: NSObject & Sendable] {
        guard let settings = try? BTBatterySettings(
            minCharge: Int(self.minCharge),
            maxCharge: Int(self.maxCharge),
            lowPowerModeThreshold: Int(self.lowPowerModeThreshold),
            capabilities: BTChargeController.capabilities
        ) else {
            assertionFailure("Stored battery settings are invalid")
            return [:]
        }

        return settings.payload
    }

    static func normalizeForCapabilities() {
        let limits = BTChargeController.normalizedLimits(
            minCharge: self.minCharge,
            maxCharge: self.maxCharge
        )
        guard limits.min != self.minCharge || limits.max != self.maxCharge else {
            return
        }

        self.minCharge = limits.min
        self.maxCharge = limits.max
        self.writeDefaults()
    }

    static func setSettings(
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        let parsedSettings: BTBatterySettings
        do {
            parsedSettings = try BTBatterySettings(payload: settings)
        } catch {
            reply(BTError.malformedData.rawValue)
            return
        }

        let success = self.setChargeLimits(
            minCharge: parsedSettings.minCharge,
            maxCharge: parsedSettings.maxCharge
        )
        guard success else {
            reply(BTError.malformedData.rawValue)
            return
        }

        self.setLowPowerModeThreshold(parsedSettings.lowPowerModeThreshold)

        self.writeDefaults()

        reply(BTError.success.rawValue)
    }

    private static func setChargeLimits(
        minCharge: Int,
        maxCharge: Int
    ) -> Bool {
        guard
            BTSettingsInfo.chargeLimitsValid(
                minCharge: minCharge,
                maxCharge: maxCharge
            ),
            BTChargeController.capabilities.supports(maxCharge: maxCharge)
        else {
            os_log("Client charge limits malformed, preserve current values")
            return false
        }

        let limits = BTChargeController.normalizedLimits(
            minCharge: UInt8(minCharge),
            maxCharge: UInt8(maxCharge)
        )
        let previousMin = self.minCharge
        let previousMax = self.maxCharge
        self.minCharge = limits.min
        self.maxCharge = limits.max

        guard BTPowerEvents.settingsChanged() else {
            self.minCharge = previousMin
            self.maxCharge = previousMax
            _ = BTPowerEvents.settingsChanged()
            return false
        }

        return true
    }

    private static func setLowPowerModeThreshold(_ threshold: Int) {
        let value = UInt8(threshold)
        guard self.lowPowerModeThreshold != value else {
            return
        }

        self.lowPowerModeThreshold = value
        BTPowerEvents.lowPowerModeThresholdChanged()
    }

    private static func writeDefaults() {
        assert(
            BTSettingsInfo.chargeLimitsValid(
                minCharge: Int(self.minCharge),
                maxCharge: Int(self.maxCharge)
            )
        )

        UserDefaults.standard.set(
            self.minCharge,
            forKey: BTSettingsInfo.Keys.minCharge
        )
        UserDefaults.standard.set(
            self.maxCharge,
            forKey: BTSettingsInfo.Keys.maxCharge
        )
        UserDefaults.standard.set(
            self.lowPowerModeThreshold,
            forKey: BTSettingsInfo.Keys.lowPowerModeThreshold
        )
        //
        // As NSUserDefaults are not automatically synchronized without
        // NSApplication, do so manually.
        //
        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}
