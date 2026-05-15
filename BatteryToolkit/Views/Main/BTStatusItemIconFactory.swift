//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal enum BTStatusItemIconFactory {
    static func percentImage(
        percent: UInt8?,
        fallback: NSImage?
    ) -> NSImage? {
        guard let percent else {
            return fallback
        }

        let size = NSSize(width: 34, height: 18)
        return NSImage(size: size, flipped: false) { rect in
            self.drawPercentBadge(percent: percent, in: rect)
            return true
        }
    }

    private static func drawPercentBadge(percent: UInt8, in rect: NSRect) {
        let isDark = NSApp.effectiveAppearance.bestMatch(
            from: [.darkAqua, .aqua]
        ) == .darkAqua
        let fillColor = isDark ?
            NSColor.white.withAlphaComponent(0.58) :
            NSColor.black.withAlphaComponent(0.12)
        let strokeColor = isDark ?
            NSColor.white.withAlphaComponent(0.28) :
            NSColor.black.withAlphaComponent(0.16)
        let textColor = isDark ?
            NSColor.black.withAlphaComponent(0.76) :
            NSColor.black.withAlphaComponent(0.78)

        let badgeRect = rect.insetBy(dx: 2, dy: 1)
        let badgePath = NSBezierPath(
            roundedRect: badgeRect,
            xRadius: 5,
            yRadius: 5
        )

        fillColor.setFill()
        badgePath.fill()
        strokeColor.setStroke()
        badgePath.lineWidth = 0.75
        badgePath.stroke()

        self.drawPercentText(
            "\(percent)",
            color: textColor,
            in: badgeRect
        )
    }

    private static func drawPercentText(
        _ text: String,
        color: NSColor,
        in rect: NSRect
    ) {
        let fontSize: CGFloat = text.count >= 3 ? 9 : 10
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: fontSize,
                weight: .semibold
            ),
            .foregroundColor: color,
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2 - 0.25,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)
    }
}
