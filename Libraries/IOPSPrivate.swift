//
// Copyright (C) 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import IOKit
import IOKit.ps
import notify
import os.log

public enum IOPSPrivate {
    static let kIOPSNotifyPercentChange = "com.apple.system.powersources.percent"

    private static let kPSTimeRemainingNotifyExternalBit: UInt64 = 1 << 16
    private static let kPSTimeRemainingNotifyChargingBit: UInt64 = 1 << 17
    private static let kPSTimeRemainingNotifyValidBit: UInt64 = 1 << 19
    private static let kPSTimeRemainingNotifyFullyChargedBit: UInt64 = 1 << 21

    static func GetPercentRemaining() -> (UInt8, Bool, Bool)? {
        guard let packedBatteryBits = GetPackedBatteryBits() else {
            return nil
        }

        let percent = UInt8(min((packedBatteryBits & 0xFF), 100))
        let isCharging = ((packedBatteryBits & kPSTimeRemainingNotifyChargingBit) != 0)
        let isFullyCharged = ((packedBatteryBits & kPSTimeRemainingNotifyFullyChargedBit) != 0)

        return (percent, isCharging, isFullyCharged)
    }

    static func DrawingUnlimitedPower() -> Bool {
        guard let packedBatteryBits = GetPackedBatteryBits() else {
            return true
        }

        return (packedBatteryBits & kPSTimeRemainingNotifyExternalBit) != 0
    }

    static func OptimizedBatteryChargingEngaged() -> Bool {
        guard
            let powerSources = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let powerSourceList = IOPSCopyPowerSourcesList(powerSources)?
                .takeRetainedValue() as? [CFTypeRef]
        else {
            return false
        }

        for source in powerSourceList {
            guard
                let description = IOPSGetPowerSourceDescription(
                    powerSources,
                    source
                )?.takeUnretainedValue() as? [String: Any],
                let engaged = description[
                    "Optimized Battery Charging Engaged"
                ] as? Bool
            else {
                continue
            }

            if engaged {
                return true
            }
        }

        return false
    }
    
    private static func GetPackedBatteryBits() -> UInt64? {
        var token: Int32 = 0
        let status = notify_register_check(kIOPSNotifyPercentChange, &token)
        guard status == NOTIFY_STATUS_OK else {
            os_log("Failed to retrieve packed battery bits - \(status)")
            return nil
        }

        var packedBatteryBits: UInt64 = 0
        notify_get_state(token, &packedBatteryBits)
        notify_cancel(token)

        if ((packedBatteryBits & kPSTimeRemainingNotifyValidBit) == 0) {
            os_log("Invalid packed battery bits - \(packedBatteryBits)")
            return nil
        }

        return packedBatteryBits
    }
}
