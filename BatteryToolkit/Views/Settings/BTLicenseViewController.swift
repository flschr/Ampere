//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal final class BTLicenseViewController: NSViewController {
    private static let contentSize = NSSize(width: 520, height: 440)

    init() {
        super.init(nibName: nil, bundle: nil)
        self.preferredContentSize = Self.contentSize
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        self.view = NSView(
            frame: NSRect(origin: .zero, size: Self.contentSize)
        )
        self.buildView()
    }

    @objc private func closeButtonAction(_: NSButton) {
        self.dismiss(nil)
    }

    private func buildView() {
        let title = NSTextField(
            labelWithString: BTLocalization.Settings.About.licenseTitle
        )
        title.font = .boldSystemFont(ofSize: 17)

        let summary = NSTextField(
            wrappingLabelWithString:
                BTLocalization.Settings.About.licenseSummary
        )
        let licenseView = self.makeLicenseView()
        let footer = self.makeFooterView()

        let stack = NSStackView(views: [title, summary, licenseView, footer])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14

        self.view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: 24
            ),
            stack.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor,
                constant: -24
            ),
            stack.topAnchor.constraint(
                equalTo: self.view.topAnchor,
                constant: 24
            ),
            stack.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor,
                constant: -20
            ),
            summary.widthAnchor.constraint(equalTo: stack.widthAnchor),
            licenseView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            licenseView.heightAnchor.constraint(equalToConstant: 300),
            footer.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func makeLicenseView() -> NSView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = self.makeLicenseTextView()

        return scrollView
    }

    private func makeLicenseTextView() -> NSTextView {
        let textView = NSTextView(
            frame: NSRect(
                origin: .zero,
                size: NSSize(width: Self.contentSize.width - 58, height: 420)
            )
        )
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isHorizontallyResizable = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.font = .monospacedSystemFont(
            ofSize: NSFont.smallSystemFontSize,
            weight: .regular
        )
        textView.string = BTAboutInfo.licenseText
        textView.textColor = .secondaryLabelColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.containerSize = NSSize(
            width: Self.contentSize.width - 58,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        return textView
    }

    private func makeFooterView() -> NSView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let closeButton = NSButton(
            title: BTLocalization.Settings.About.close,
            target: self,
            action: #selector(self.closeButtonAction(_:))
        )
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\r"

        let stack = NSStackView(views: [spacer, closeButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12

        return stack
    }
}
