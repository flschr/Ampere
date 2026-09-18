//
// Copyright (C) 2022 - 2023 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

import IOPMPrivate

@MainActor
public enum GlobalSleep {
    /// Shutdown may happen before the system accepts a sleep-state restore.
    /// Persist an actual override so the next daemon start can retry it.
    private static let previousSleepDisabledKey = "PreviousSleepDisabled"

    /// Active charging and short-lived setup phases can overlap. Use a counter
    /// so each source restores only its own sleep-prevention request.
    private static var disabledCounter: UInt8 = 0

    /// Honour the user-specified sleep disabled state for restoration.
    private static var previousDisabled: Bool?

    static func restoreOnStart() {
        guard let value = UserDefaults.standard.object(
            forKey: self.previousSleepDisabledKey
        ) as? Bool else {
            return
        }

        // Older versions also stored true although they changed nothing.
        // Never replay that stale value over a newer user choice.
        if value || self.setSleepDisabledIOPMValue(value: kCFBooleanFalse) {
            self.clearPreviousSleepDisabled()
        } else {
            // Keep the original state in memory as well: another charging
            // cycle must not mistake our still-active override for user intent.
            self.previousDisabled = false
        }
    }

    static func forceRestore() {
        self.disabledCounter = 0
        self.restorePrevious()
    }

    static func restore() {
        assert(self.disabledCounter > 0)
        self.disabledCounter -= 1

        guard self.disabledCounter == 0 else {
            return
        }

        self.restorePrevious()
    }

    static func disable() {
        assert(self.disabledCounter >= 0)
        self.disabledCounter += 1

        guard self.disabledCounter == 1 else {
            return
        }

        if self.previousDisabled == nil {
            guard let sleepDisable = self.getSleepDisabledIOPMValue() else {
                return
            }
            self.previousDisabled = sleepDisable
            if !sleepDisable {
                UserDefaults.standard.setValue(
                    false,
                    forKey: self.previousSleepDisabledKey
                )
                guard CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication) else {
                    os_log("Failed to persist the previous sleep state")
                    self.previousDisabled = nil
                    self.clearPreviousSleepDisabled()
                    return
                }
            }
        }

        guard self.previousDisabled == false else {
            return
        }

        if !self.setSleepDisabledIOPMValue(value: kCFBooleanTrue),
            self.getSleepDisabledIOPMValue() == false {
            // No override was applied, so there is nothing to replay on boot.
            self.previousDisabled = nil
            self.clearPreviousSleepDisabled()
        }
    }

    private static func getSleepDisabledIOPMValue() -> Bool? {
        guard let settingsRef = IOPMCopySystemPowerSettings() else {
            os_log("System power settings could not be retrieved")
            return nil
        }

        guard
            let settings =
            settingsRef.takeUnretainedValue() as? [String: AnyObject]
        else {
            os_log("System power settings are malformed")
            return nil
        }

        guard let sleepDisable = settings[kIOPMSleepDisabledKey] as? Bool else {
            os_log("Sleep disable setting is malformed")
            return nil
        }

        return sleepDisable
    }

    @discardableResult
    private static func setSleepDisabledIOPMValue(value: CFBoolean) -> Bool {
        let result = IOPMSetSystemPowerSetting(
            kIOPMSleepDisabledKey as CFString,
            value
        )
        if result != kIOReturnSuccess {
            os_log("Failed to set \(value) SleepDisabled setting - \(result)")
        }
        return result == kIOReturnSuccess
    }

    private static func restorePrevious() {
        guard let previousDisabled = self.previousDisabled else {
            return
        }
        if previousDisabled || self.setSleepDisabledIOPMValue(value: kCFBooleanFalse) {
            self.previousDisabled = nil
            self.clearPreviousSleepDisabled()
        }
    }

    private static func clearPreviousSleepDisabled() {
        UserDefaults.standard.removeObject(forKey: self.previousSleepDisabledKey)
        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}
