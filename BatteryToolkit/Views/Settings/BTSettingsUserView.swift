//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal final class BTSettingsUserView: NSView {
    let autostartSwitch = NSSwitch()

    init(uninstallTarget: AnyObject, uninstallAction: Selector) {
        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.buildView(
            uninstallTarget: uninstallTarget,
            uninstallAction: uninstallAction
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView(
        uninstallTarget: AnyObject,
        uninstallAction: Selector
    ) {
        let autostartLabel = NSTextField(
            labelWithString: BTLocalization.Settings.autostart
        )
        autostartLabel.translatesAutoresizingMaskIntoConstraints = false
        autostartLabel.lineBreakMode = .byWordWrapping
        autostartLabel.maximumNumberOfLines = 2
        autostartLabel.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        let autostartInfo = NSTextField(
            wrappingLabelWithString: BTLocalization.Settings.menuBarExtraInfo
        )
        autostartInfo.translatesAutoresizingMaskIntoConstraints = false
        autostartInfo.textColor = .secondaryLabelColor
        autostartInfo.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        self.autostartSwitch.translatesAutoresizingMaskIntoConstraints = false
        self.autostartSwitch.controlSize = .mini

        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator

        let uninstallTitle = NSTextField(
            labelWithString: BTLocalization.Settings.uninstall
        )
        uninstallTitle.translatesAutoresizingMaskIntoConstraints = false
        uninstallTitle.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        let uninstallInfo = NSTextField(
            wrappingLabelWithString: BTLocalization.Settings.uninstallInfo
        )
        uninstallInfo.translatesAutoresizingMaskIntoConstraints = false
        uninstallInfo.textColor = .secondaryLabelColor
        uninstallInfo.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        let uninstallButton = NSButton(
            title: BTLocalization.Settings.uninstallBatteryToolkit,
            target: uninstallTarget,
            action: uninstallAction
        )
        uninstallButton.translatesAutoresizingMaskIntoConstraints = false
        uninstallButton.bezelStyle = .rounded

        for subview in [
            autostartLabel,
            autostartInfo,
            self.autostartSwitch,
            separator,
            uninstallTitle,
            uninstallInfo,
            uninstallButton,
        ] {
            self.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            autostartLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: 20
            ),
            autostartLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: 20
            ),
            self.autostartSwitch.leadingAnchor.constraint(
                equalTo: autostartLabel.trailingAnchor,
                constant: 18
            ),
            self.autostartSwitch.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -20
            ),
            self.autostartSwitch.centerYAnchor.constraint(
                equalTo: autostartLabel.centerYAnchor
            ),

            autostartInfo.topAnchor.constraint(
                equalTo: autostartLabel.bottomAnchor,
                constant: 3
            ),
            autostartInfo.leadingAnchor.constraint(
                equalTo: autostartLabel.leadingAnchor
            ),
            autostartInfo.trailingAnchor.constraint(
                lessThanOrEqualTo: self.autostartSwitch.leadingAnchor,
                constant: -18
            ),

            separator.topAnchor.constraint(
                equalTo: autostartInfo.bottomAnchor,
                constant: 20
            ),
            separator.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: 20
            ),
            separator.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -20
            ),

            uninstallTitle.topAnchor.constraint(
                equalTo: separator.bottomAnchor,
                constant: 20
            ),
            uninstallTitle.leadingAnchor.constraint(
                equalTo: autostartLabel.leadingAnchor
            ),
            uninstallTitle.trailingAnchor.constraint(
                lessThanOrEqualTo: self.trailingAnchor,
                constant: -20
            ),

            uninstallInfo.topAnchor.constraint(
                equalTo: uninstallTitle.bottomAnchor,
                constant: 3
            ),
            uninstallInfo.leadingAnchor.constraint(
                equalTo: uninstallTitle.leadingAnchor
            ),
            uninstallInfo.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -20
            ),

            uninstallButton.topAnchor.constraint(
                equalTo: uninstallInfo.bottomAnchor,
                constant: 12
            ),
            uninstallButton.leadingAnchor.constraint(
                equalTo: uninstallTitle.leadingAnchor
            ),
            uninstallButton.bottomAnchor.constraint(
                lessThanOrEqualTo: self.bottomAnchor,
                constant: -20
            ),
        ])
    }
}
