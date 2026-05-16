//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
extension BTAboutInfoViewFactory {
    func makeActionButton(
        title: String,
        systemSymbolName: String,
        action: Selector
    ) -> NSButton {
        let button = NSButton(
            title: title,
            target: self.target,
            action: action
        )
        button.bezelStyle = .rounded
        button.image = NSImage(
            systemSymbolName: systemSymbolName,
            accessibilityDescription: title
        )
        button.imagePosition = .imageLeading
        button.setContentHuggingPriority(.required, for: .horizontal)

        return button
    }

    func makeFooterView() -> NSView {
        let uninstallButton = NSButton(
            title: BTLocalization.Settings.uninstallBatteryToolkit,
            target: self.target,
            action: self.uninstallAction
        )
        uninstallButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let closeButton = NSButton(
            title: BTLocalization.Settings.About.close,
            target: self.target,
            action: self.closeAction
        )
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\r"

        let stack = NSStackView(views: [uninstallButton, spacer, closeButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12

        return stack
    }
}
