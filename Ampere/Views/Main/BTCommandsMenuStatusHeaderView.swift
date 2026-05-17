//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal final class BTCommandsMenuStatusHeaderView: NSView {
    private enum Metrics {
        static let width: CGFloat = 360
        static let height: CGFloat = 30
        static let leadingInset: CGFloat = 22
        static let trailingInset: CGFloat = 14
        static let verticalInset: CGFloat = 6
    }

    init(title: String) {
        super.init(
            frame: NSRect(
                x: 0,
                y: 0,
                width: Metrics.width,
                height: Metrics.height
            )
        )

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Metrics.leadingInset
            ),
            label.trailingAnchor.constraint(
                lessThanOrEqualTo: self.trailingAnchor,
                constant: -Metrics.trailingInset
            ),
            label.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: Metrics.verticalInset
            ),
            label.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -Metrics.verticalInset
            ),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
