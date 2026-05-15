//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal struct BTStatusItemSnapshot {
    let title: String
    let image: NSImage?
    let toolTip: String
}

@MainActor
internal enum BTStatusItemSnapshotFactory {
    static func make(
        state: [String: NSObject & Sendable],
        settings: [String: NSObject & Sendable],
        percent: UInt8?
    ) -> BTStatusItemSnapshot {
        let title = percent.map { "\($0)%" } ?? ""
        let enabled = (state[BTStateInfo.Keys.enabled] as? NSNumber)?.boolValue
        guard enabled == true else {
            return self.snapshot(
                title: title,
                symbol: "pause.circle",
                toolTip: BTLocalization.StatusItem.paused
            )
        }

        let powerDisabled =
            (state[BTStateInfo.Keys.powerDisabled] as? NSNumber)?.boolValue
        if powerDisabled == true {
            return self.snapshot(
                title: title,
                symbol: "battery.0",
                toolTip: BTLocalization.StatusItem.adapterDisabled
            )
        }

        let chargingDisabled =
            (state[BTStateInfo.Keys.chargingDisabled] as? NSNumber)?.boolValue
        guard chargingDisabled == true else {
            return self.chargingSnapshot(
                title: title,
                state: state
            )
        }

        let minCharge =
            (settings[BTSettingsInfo.Keys.minCharge] as? NSNumber)?.intValue
        let toolTip = minCharge.map {
            BTLocalization.StatusItem.holding(minCharge: $0)
        } ?? BTLocalization.StatusItem.holdingUnknown
        return self.snapshot(title: title, symbol: "battery.75", toolTip: toolTip)
    }

    static func unknown(percent: UInt8?) -> BTStatusItemSnapshot {
        self.snapshot(
            title: percent.map { "\($0)%" } ?? "",
            symbol: "exclamationmark.triangle",
            toolTip: BTLocalization.StatusItem.unknown
        )
    }

    private static func chargingSnapshot(
        title: String,
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

        return self.snapshot(
            title: title,
            symbol: "battery.100.bolt",
            toolTip: toolTip
        )
    }

    private static func snapshot(
        title: String,
        symbol: String,
        toolTip: String
    ) -> BTStatusItemSnapshot {
        let image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: toolTip
        ) ?? NSImage(named: NSImage.Name("ExtraItemIcon"))
        image?.isTemplate = true

        return BTStatusItemSnapshot(
            title: title,
            image: image,
            toolTip: toolTip
        )
    }
}
