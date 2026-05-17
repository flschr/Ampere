//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal enum BTStatusItemSymbolImage {
    private static let configuration = NSImage.SymbolConfiguration(
        pointSize: 13,
        weight: .regular
    )

    static func make(
        named symbol: String,
        accessibilityDescription: String,
        isTemplate: Bool = true
    ) -> NSImage? {
        for candidate in [
            symbol,
            "exclamationmark.triangle",
            "questionmark.circle",
        ] {
            guard let image = self.configuredImage(
                named: candidate,
                accessibilityDescription: accessibilityDescription
            ) else {
                continue
            }

            image.isTemplate = isTemplate
            return image
        }

        return nil
    }

    private static func configuredImage(
        named symbol: String,
        accessibilityDescription: String
    ) -> NSImage? {
        guard let image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: accessibilityDescription
        ) else {
            return nil
        }

        return image.withSymbolConfiguration(self.configuration) ?? image
    }
}
