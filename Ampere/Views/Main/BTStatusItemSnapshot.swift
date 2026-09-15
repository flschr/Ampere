//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal struct BTStatusItemSnapshot {
    let image: NSImage?
    let title: String
    let toolTip: String
    let contentTintColor: NSColor?
}

@MainActor
internal enum BTStatusItemSnapshotFactory {
    static func make(
        state: [String: NSObject & Sendable],
        settings: [String: NSObject & Sendable],
        lowPowerModeEnabled: Bool
    ) -> BTStatusItemSnapshot {
        let enabled = (state[BTStateInfo.Keys.enabled] as? NSNumber)?.boolValue
        guard enabled == true else {
            return self.snapshot(
                symbol: "pause.circle",
                title: "",
                toolTip: BTLocalization.StatusItem.paused
            )
        }

        let batteryPercent =
            (state[BTStateInfo.Keys.batteryPercent] as? NSNumber)?.intValue
        let powerDisabled =
            (state[BTStateInfo.Keys.powerDisabled] as? NSNumber)?.boolValue
        let connected =
            (state[BTStateInfo.Keys.connected] as? NSNumber)?.boolValue
        let effectiveLowPowerModeEnabled =
            lowPowerModeEnabled && !(connected == true && powerDisabled != true)
        if powerDisabled == true {
            return self.batterySnapshot(
                percent: batteryPercent,
                isCharging: false,
                lowPowerModeEnabled: effectiveLowPowerModeEnabled,
                toolTip: self.toolTip(
                    status: BTLocalization.StatusItem.adapterDisabled,
                    percent: batteryPercent
                )
            )
        }

        if connected == false {
            let toolTip = batteryPercent.map {
                BTLocalization.StatusItem.batteryLevel(percent: $0)
            } ?? BTLocalization.StatusItem.unknown
            return self.batterySnapshot(
                percent: batteryPercent,
                isCharging: false,
                lowPowerModeEnabled: effectiveLowPowerModeEnabled,
                toolTip: toolTip
            )
        }

        let chargingDisabled =
            (state[BTStateInfo.Keys.chargingDisabled] as? NSNumber)?.boolValue
        guard chargingDisabled == true else {
            return self.chargingSnapshot(
                state: state,
                lowPowerModeEnabled: effectiveLowPowerModeEnabled
            )
        }

        let minCharge =
            (settings[BTSettingsInfo.Keys.minCharge] as? NSNumber)?.intValue
        let thermallyLimited =
            (state[BTStateInfo.Keys.thermallyLimited] as? NSNumber)?.boolValue
        let toolTip: String
        if thermallyLimited == true {
            toolTip = BTLocalization.StatusItem.holdingHotBattery
        } else {
            toolTip = minCharge.map {
                BTLocalization.StatusItem.holding(minCharge: $0)
            } ?? BTLocalization.StatusItem.holdingUnknown
        }
        return self.batterySnapshot(
            percent: batteryPercent,
            isCharging: false,
            lowPowerModeEnabled: effectiveLowPowerModeEnabled,
            toolTip: self.toolTip(status: toolTip, percent: batteryPercent)
        )
    }

    static func unknown() -> BTStatusItemSnapshot {
        self.snapshot(
            symbol: "exclamationmark.triangle",
            title: "",
            toolTip: BTLocalization.StatusItem.unknown
        )
    }

    private static func chargingSnapshot(
        state: [String: NSObject & Sendable],
        lowPowerModeEnabled: Bool
    ) -> BTStatusItemSnapshot {
        let chargingMode =
            (state[BTStateInfo.Keys.chargingMode] as? NSNumber)?.intValue
        let maxCharge =
            (state[BTStateInfo.Keys.maxCharge] as? NSNumber)?.intValue

        let toolTip: String
        switch chargingMode {
        case Int(BTStateInfo.ChargingMode.toFull.rawValue):
            toolTip = BTLocalization.StatusItem.chargingToFull

        default:
            toolTip = maxCharge.map {
                BTLocalization.StatusItem.chargingUntil(maxCharge: $0)
            } ?? BTLocalization.StatusItem.charging
        }

        let batteryPercent =
            (state[BTStateInfo.Keys.batteryPercent] as? NSNumber)?.intValue
        return self.batterySnapshot(
            percent: batteryPercent,
            isCharging: true,
            lowPowerModeEnabled: lowPowerModeEnabled,
            toolTip: self.toolTip(status: toolTip, percent: batteryPercent)
        )
    }

    private static func batterySnapshot(
        percent: Int?,
        isCharging: Bool,
        lowPowerModeEnabled: Bool,
        toolTip: String
    ) -> BTStatusItemSnapshot {
        self.snapshot(
            symbol: self.batterySymbol(
                percent: percent,
                isCharging: isCharging
            ),
            image: BTStatusItemBatteryImage.make(
                isCharging: isCharging,
                lowPowerModeEnabled: lowPowerModeEnabled
            ),
            title: self.percentTitle(percent),
            toolTip: toolTip
        )
    }

    private static func percentTitle(_ percent: Int?) -> String {
        percent.map { "\($0) %" } ?? ""
    }

    private static func batterySymbol(
        percent: Int?,
        isCharging: Bool
    ) -> String {
        if isCharging {
            return "battery.100.bolt"
        }

        guard let percent else {
            return "battery.0"
        }

        switch percent {
        case ..<13:
            return "battery.0"
        case ..<38:
            return "battery.25"
        case ..<63:
            return "battery.50"
        case ..<88:
            return "battery.75"
        default:
            return "battery.100"
        }
    }

    private static func toolTip(status: String, percent: Int?) -> String {
        guard let percent else {
            return status
        }

        return "\(status), \(BTLocalization.StatusItem.batteryLevel(percent: percent))"
    }

    private static func snapshot(
        symbol: String,
        image customImage: NSImage? = nil,
        title: String,
        toolTip: String
    ) -> BTStatusItemSnapshot {
        return BTStatusItemSnapshot(
            image: customImage ?? BTStatusItemSymbolImage.make(
                named: symbol,
                accessibilityDescription: toolTip
            ),
            title: title,
            toolTip: toolTip,
            contentTintColor: nil
        )
    }
}
