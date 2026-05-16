//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal final class BTSettingsUserView: NSView {
    let autostartSwitch = NSSwitch()

    init() {
        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.buildView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView() {
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

        for subview in [
            autostartLabel,
            autostartInfo,
            self.autostartSwitch,
        ] {
            self.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            autostartLabel.topAnchor.constraint(
                equalTo: self.topAnchor
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

            autostartInfo.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -20
            ),
        ])
    }
}
