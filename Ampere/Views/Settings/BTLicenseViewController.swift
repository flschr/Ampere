//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal final class BTLicenseViewController: NSViewController {
    private static let contentSize = NSSize(width: 620, height: 520)
    private weak var licenseTextView: NSTextView?

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

    override func viewDidAppear() {
        super.viewDidAppear()
        self.licenseTextView?.scrollToBeginningOfDocument(nil)
    }

    @objc private func closeButtonAction(_: NSButton) {
        self.dismiss(nil)
    }

    private func buildView() {
        let title = NSTextField(
            labelWithString: BTLocalization.Settings.About.licensesTitle
        )
        title.font = .boldSystemFont(ofSize: 17)

        let summary = NSTextField(
            wrappingLabelWithString:
                BTLocalization.Settings.About.licenseSummary
        )
        summary.setContentCompressionResistancePriority(
            .required,
            for: .vertical
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
            licenseView.heightAnchor.constraint(equalToConstant: 344),
            footer.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func makeLicenseView() -> NSView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 8
        scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
        scrollView.layer?.borderWidth = 1
        scrollView.documentView = self.makeLicenseTextView()

        return scrollView
    }

    private func makeLicenseTextView() -> NSTextView {
        let textView = NSTextView(
            frame: NSRect(
                origin: .zero,
                size: NSSize(width: Self.contentSize.width - 70, height: 720)
            )
        )
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isHorizontallyResizable = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.textStorage?.setAttributedString(
            self.makeLicenseAttributedText()
        )
        textView.textContainer?.containerSize = NSSize(
            width: Self.contentSize.width - 98,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        self.licenseTextView = textView

        return textView
    }

    private func makeLicenseAttributedText() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 10

        let attributedText = NSMutableAttributedString(
            string: BTAboutInfo.licenseText,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12.5),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle,
            ]
        )
        self.applyHeading("BSD 3-Clause License", to: attributedText)
        self.applyHeading("Attribution", to: attributedText)

        return attributedText
    }

    private func applyHeading(
        _ heading: String,
        to attributedText: NSMutableAttributedString
    ) {
        let range = (attributedText.string as NSString).range(of: heading)
        guard range.location != NSNotFound else {
            return
        }

        attributedText.addAttributes(
            [
                .font: NSFont.boldSystemFont(ofSize: 13.5),
                .foregroundColor: NSColor.labelColor,
            ],
            range: range
        )
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
