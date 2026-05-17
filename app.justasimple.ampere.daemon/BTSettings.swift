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
    private(set) static var adapterSleep = BTSettingsInfo.Defaults.adapterSleep
    private(set) static var magSafeSync = BTSettingsInfo.Defaults.magSafeSync

    static func readDefaults() {
        self.adapterSleep = UserDefaults.standard.bool(
            forKey: BTSettingsInfo.Keys.adapterSleep
        )
        self.magSafeSync = UserDefaults.standard.bool(
            forKey: BTSettingsInfo.Keys.magSafeSync
        )

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

        self.minCharge = UInt8(minCharge)
        self.maxCharge = UInt8(maxCharge)
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

        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    static func getSettings() -> [String: NSObject & Sendable] {
        guard let settings = try? BTBatterySettings(
            minCharge: Int(self.minCharge),
            maxCharge: Int(self.maxCharge),
            adapterSleep: self.adapterSleep,
            magSafeSync: SMCComm.MagSafe.supported ? self.magSafeSync : nil
        ) else {
            assertionFailure("Stored battery settings are invalid")
            return [:]
        }

        return settings.payload
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

        self.setAdapterSleep(enabled: parsedSettings.adapterSleep)

        if let magSafeSync = parsedSettings.magSafeSync {
            self.setMagSafeSync(enabled: magSafeSync)
        }

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
            )
        else {
            os_log("Client charge limits malformed, preserve current values")
            return false
        }

        self.minCharge = UInt8(minCharge)
        self.maxCharge = UInt8(maxCharge)

        BTPowerEvents.settingsChanged()

        return true
    }

    private static func setAdapterSleep(enabled: Bool) {
        guard self.adapterSleep != enabled else {
            return
        }

        self.adapterSleep = enabled

        BTPowerState.adapterSleepSettingToggled()
    }

    private static func setMagSafeSync(enabled: Bool) {
        guard self.magSafeSync != enabled else {
            return
        }

        self.magSafeSync = enabled

        BTPowerState.magSafeSyncSettingToggled()
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
            self.adapterSleep,
            forKey: BTSettingsInfo.Keys.adapterSleep
        )
        UserDefaults.standard.set(
            self.magSafeSync,
            forKey: BTSettingsInfo.Keys.magSafeSync
        )
        //
        // As NSUserDefaults are not automatically synchronized without
        // NSApplication, do so manually.
        //
        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}
