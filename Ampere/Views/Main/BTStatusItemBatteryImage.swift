//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal enum BTStatusItemBatteryImage {
    private static let size = NSSize(width: 20, height: 12)

    static func make(
        isCharging: Bool,
        lowPowerModeEnabled: Bool
    ) -> NSImage {
        let image = NSImage(size: self.size, flipped: false) { _ in
            self.draw(
                isCharging: isCharging,
                lowPowerModeEnabled: lowPowerModeEnabled
            )
            return true
        }

        image.isTemplate = !lowPowerModeEnabled
        return image
    }

    private static func draw(
        isCharging: Bool,
        lowPowerModeEnabled: Bool
    ) {
        let bodyRect = NSRect(x: 0.8, y: 1.6, width: 16.6, height: 8.8)
        let capRect = NSRect(x: 17.2, y: 4.2, width: 2.0, height: 3.6)
        let fillRect = NSRect(x: 2.5, y: 3.2, width: 13.2, height: 5.6)
        let bodyPath = NSBezierPath(
            roundedRect: bodyRect,
            xRadius: 2.4,
            yRadius: 2.4
        )
        let capPath = NSBezierPath(
            roundedRect: capRect,
            xRadius: 0.9,
            yRadius: 0.9
        )
        let shapeColor = lowPowerModeEnabled ? NSColor.labelColor : .black

        shapeColor.setFill()
        capPath.fill()

        if !isCharging {
            self.drawFill(
                fillRect: fillRect,
                clipPath: bodyPath,
                fillColor: lowPowerModeEnabled ? .systemYellow : shapeColor
            )
        }

        bodyPath.lineWidth = 1.25
        shapeColor.setStroke()
        bodyPath.stroke()

        if isCharging {
            shapeColor.setFill()
            self.boltPath().fill()
        }
    }

    private static func drawFill(
        fillRect: NSRect,
        clipPath: NSBezierPath,
        fillColor: NSColor
    ) {
        let visualFillRect = NSRect(
            x: fillRect.minX,
            y: fillRect.minY,
            width: fillRect.width * 0.5,
            height: fillRect.height
        )
        let fillPath = NSBezierPath(
            roundedRect: visualFillRect,
            xRadius: 1.2,
            yRadius: 1.2
        )

        NSGraphicsContext.saveGraphicsState()
        clipPath.addClip()
        fillColor.setFill()
        fillPath.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func boltPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 10.5, y: 9.9))
        path.line(to: NSPoint(x: 6.3, y: 5.4))
        path.line(to: NSPoint(x: 8.5, y: 5.4))
        path.line(to: NSPoint(x: 6.9, y: 2.0))
        path.line(to: NSPoint(x: 12.0, y: 6.8))
        path.line(to: NSPoint(x: 9.6, y: 6.8))
        path.close()
        return path
    }
}
