//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal struct BTStatusItemSnapshot {
    let image: NSImage?
    let title: String
    let toolTip: String
}

@MainActor
internal enum BTStatusItemSnapshotFactory {
    static func make(
        state: [String: NSObject & Sendable],
        settings: [String: NSObject & Sendable]
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
        if powerDisabled == true {
            return self.batterySnapshot(
                percent: batteryPercent,
                isCharging: false,
                toolTip: self.toolTip(
                    status: BTLocalization.StatusItem.adapterDisabled,
                    percent: batteryPercent
                )
            )
        }

        let connected =
            (state[BTStateInfo.Keys.connected] as? NSNumber)?.boolValue
        if connected == false {
            let toolTip = batteryPercent.map {
                BTLocalization.StatusItem.batteryLevel(percent: $0)
            } ?? BTLocalization.StatusItem.unknown
            return self.batterySnapshot(
                percent: batteryPercent,
                isCharging: false,
                toolTip: toolTip
            )
        }

        let chargingDisabled =
            (state[BTStateInfo.Keys.chargingDisabled] as? NSNumber)?.boolValue
        guard chargingDisabled == true else {
            return self.chargingSnapshot(
                state: state
            )
        }

        let minCharge =
            (settings[BTSettingsInfo.Keys.minCharge] as? NSNumber)?.intValue
        let toolTip = minCharge.map {
            BTLocalization.StatusItem.holding(minCharge: $0)
        } ?? BTLocalization.StatusItem.holdingUnknown
        return self.batterySnapshot(
            percent: batteryPercent,
            isCharging: false,
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
        state: [String: NSObject & Sendable]
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
            toolTip: self.toolTip(status: toolTip, percent: batteryPercent)
        )
    }

    private static func batterySnapshot(
        percent: Int?,
        isCharging: Bool,
        toolTip: String
    ) -> BTStatusItemSnapshot {
        self.snapshot(
            symbol: self.batterySymbol(
                percent: percent,
                isCharging: isCharging
            ),
            title: percent.map { "\($0) %" } ?? "",
            toolTip: toolTip
        )
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
        title: String,
        toolTip: String
    ) -> BTStatusItemSnapshot {
        let image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: toolTip
        ) ?? NSImage(named: NSImage.Name("ExtraItemIcon"))
        image?.isTemplate = true

        return BTStatusItemSnapshot(
            image: image,
            title: title,
            toolTip: toolTip
        )
    }
}
