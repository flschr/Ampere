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
        if powerDisabled == true {
            return self.batterySnapshot(
                percent: batteryPercent,
                isCharging: false,
                lowPowerModeEnabled: lowPowerModeEnabled,
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
                lowPowerModeEnabled: lowPowerModeEnabled,
                toolTip: toolTip
            )
        }

        let chargingDisabled =
            (state[BTStateInfo.Keys.chargingDisabled] as? NSNumber)?.boolValue
        guard chargingDisabled == true else {
            return self.chargingSnapshot(
                state: state,
                lowPowerModeEnabled: lowPowerModeEnabled
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
            lowPowerModeEnabled: lowPowerModeEnabled,
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
            image: lowPowerModeEnabled ? self.lowPowerBatteryImage(
                percent: percent,
                isCharging: isCharging,
                accessibilityDescription: toolTip
            ) : nil,
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
        image customImage: NSImage? = nil,
        title: String,
        toolTip: String
    ) -> BTStatusItemSnapshot {
        let image = customImage ?? NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: toolTip
        ) ?? NSImage(named: NSImage.Name("ExtraItemIcon"))
        if customImage == nil {
            image?.isTemplate = true
        }

        return BTStatusItemSnapshot(
            image: image,
            title: title,
            toolTip: toolTip,
            contentTintColor: nil
        )
    }

    private static func lowPowerBatteryImage(
        percent: Int?,
        isCharging: Bool,
        accessibilityDescription: String
    ) -> NSImage {
        let image = NSImage(size: NSSize(width: 23, height: 13))
        image.accessibilityDescription = accessibilityDescription
        image.lockFocus()
        defer {
            image.unlockFocus()
        }

        let bodyRect = NSRect(x: 0.8, y: 2.4, width: 18.5, height: 8.2)
        let terminalRect = NSRect(x: 19.5, y: 5.0, width: 2.4, height: 3.0)
        let bodyPath = NSBezierPath(
            roundedRect: bodyRect,
            xRadius: 2.2,
            yRadius: 2.2
        )
        let terminalPath = NSBezierPath(
            roundedRect: terminalRect,
            xRadius: 1.0,
            yRadius: 1.0
        )

        NSColor.labelColor.setStroke()
        bodyPath.lineWidth = 1.25
        bodyPath.stroke()
        terminalPath.fill()

        let fillPercent = CGFloat(min(max(percent ?? 100, 0), 100)) / 100.0
        let fillWidth = max(1.4, (bodyRect.width - 3.0) * fillPercent)
        let fillRect = NSRect(
            x: bodyRect.minX + 1.5,
            y: bodyRect.minY + 1.5,
            width: fillWidth,
            height: bodyRect.height - 3.0
        )
        let fillPath = NSBezierPath(
            roundedRect: fillRect,
            xRadius: 1.2,
            yRadius: 1.2
        )
        NSColor.systemYellow.setFill()
        fillPath.fill()

        if isCharging {
            let bolt = NSBezierPath()
            bolt.move(to: NSPoint(x: 11.4, y: 10.8))
            bolt.line(to: NSPoint(x: 7.9, y: 5.9))
            bolt.line(to: NSPoint(x: 10.4, y: 5.9))
            bolt.line(to: NSPoint(x: 8.8, y: 1.4))
            bolt.line(to: NSPoint(x: 14.0, y: 7.2))
            bolt.line(to: NSPoint(x: 11.3, y: 7.2))
            bolt.close()
            NSColor.labelColor.setFill()
            bolt.fill()
        }

        image.isTemplate = false
        return image
    }
}
