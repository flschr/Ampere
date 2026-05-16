//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
extension BTAboutInfoViewFactory {
    func makeTextLinkRow(
        title: String,
        action: Selector
    ) -> NSView {
        let bulletLabel = NSTextField(labelWithString: "\u{2022}")
        bulletLabel.textColor = .secondaryLabelColor

        let button = self.makeTextLinkButton(title: title, action: action)
        let stack = NSStackView(views: [bulletLabel, button])
        stack.orientation = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 8

        return stack
    }

    private func makeTextLinkButton(
        title: String,
        action: Selector
    ) -> NSButton {
        let button = NSButton(
            title: title,
            target: self.target,
            action: action
        )
        button.alignment = .left
        button.isBordered = false
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: NSColor.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]
        )
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
