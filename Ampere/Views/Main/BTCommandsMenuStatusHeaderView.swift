//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal final class BTCommandsMenuStatusHeaderView: NSView {
    private enum Metrics {
        static let width: CGFloat = 360
        static let singleLineHeight: CGFloat = 30
        static let twoLineHeight: CGFloat = 48
        static let threeLineHeight: CGFloat = 64
        static let leadingInset: CGFloat = 24
        static let trailingInset: CGFloat = 14
        static let verticalInset: CGFloat = 6
        static let detailSpacing: CGFloat = 1
    }

    init(title: String, detail: String?, subdetail: String? = nil) {
        super.init(
            frame: NSRect(
                x: 0,
                y: 0,
                width: Metrics.width,
                height: detail == nil
                    ? Metrics.singleLineHeight
                    : subdetail == nil
                        ? Metrics.twoLineHeight
                        : Metrics.threeLineHeight
            )
        )

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFontManager.shared.convert(
            NSFont.menuFont(ofSize: 0),
            toHaveTrait: .boldFontMask
        )
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(titleLabel)
        let trailingConstraint = titleLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: self.trailingAnchor,
            constant: -Metrics.trailingInset
        )

        guard let detail else {
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(
                    equalTo: self.leadingAnchor,
                    constant: Metrics.leadingInset
                ),
                trailingConstraint,
                titleLabel.topAnchor.constraint(
                    equalTo: self.topAnchor,
                    constant: Metrics.verticalInset
                ),
                titleLabel.bottomAnchor.constraint(
                    equalTo: self.bottomAnchor,
                    constant: -Metrics.verticalInset
                ),
            ])
            return
        }

        let detailLabel = NSTextField(labelWithString: detail)
        detailLabel.font = .menuFont(ofSize: 0)
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(detailLabel)
        var constraints = [
            titleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Metrics.leadingInset
            ),
            trailingConstraint,
            titleLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: Metrics.verticalInset
            ),
            detailLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),
            detailLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: self.trailingAnchor,
                constant: -Metrics.trailingInset
            ),
            detailLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: Metrics.detailSpacing
            ),
        ]

        if let subdetail {
            let subdetailLabel = NSTextField(labelWithString: subdetail)
            subdetailLabel.font = .menuFont(ofSize: 0)
            subdetailLabel.lineBreakMode = .byTruncatingTail
            subdetailLabel.textColor = .secondaryLabelColor
            subdetailLabel.translatesAutoresizingMaskIntoConstraints = false

            self.addSubview(subdetailLabel)
            constraints += [
                subdetailLabel.leadingAnchor.constraint(
                    equalTo: titleLabel.leadingAnchor
                ),
                subdetailLabel.trailingAnchor.constraint(
                    lessThanOrEqualTo: self.trailingAnchor,
                    constant: -Metrics.trailingInset
                ),
                subdetailLabel.topAnchor.constraint(
                    equalTo: detailLabel.bottomAnchor,
                    constant: Metrics.detailSpacing
                ),
                subdetailLabel.bottomAnchor.constraint(
                    equalTo: self.bottomAnchor,
                    constant: -Metrics.verticalInset
                ),
            ]
        } else {
            constraints.append(
                detailLabel.bottomAnchor.constraint(
                    equalTo: self.bottomAnchor,
                    constant: -Metrics.verticalInset
                )
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
