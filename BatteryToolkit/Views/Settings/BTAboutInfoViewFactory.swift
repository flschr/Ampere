//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal struct BTAboutInfoViewFactory {
    static let contentSize = NSSize(width: 520, height: 340)

    let info: BTAboutInfo
    let target: AnyObject
    let websiteAction: Selector
    let privacyAction: Selector
    let licenseAction: Selector
    let uninstallAction: Selector
    let closeAction: Selector

    func makeView() -> NSView {
        let view = NSView(
            frame: NSRect(origin: .zero, size: Self.contentSize)
        )
        let stack = self.makeContentStack()
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -20
            ),
        ])

        return view
    }

    private func makeContentStack() -> NSStackView {
        let metadataView = self.makeMetadataView()
        let attributionSummary = self.makeAttributionSummary()
        let actionView = self.makeActionView()
        let footerView = self.makeFooterView()
        let spacerView = NSView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        let stack = NSStackView(views: [
            self.makeHeaderView(),
            metadataView,
            self.makeAttributionTitle(),
            attributionSummary,
            actionView,
            spacerView,
            footerView,
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14

        NSLayoutConstraint.activate([
            metadataView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            attributionSummary.widthAnchor.constraint(
                equalTo: stack.widthAnchor
            ),
            actionView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            footerView.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        return stack
    }

    private func makeHeaderView() -> NSView {
        let iconView = NSImageView(
            image: NSImage(named: NSImage.Name("NSApplicationIcon")) ??
                NSImage()
        )
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown

        let appNameLabel = NSTextField(labelWithString: self.info.appName)
        appNameLabel.font = .boldSystemFont(ofSize: 22)

        let versionLabel = NSTextField(
            labelWithString: self.info.versionBuildText
        )
        versionLabel.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [appNameLabel, versionLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let headerStack = NSStackView(views: [iconView, textStack])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 14

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
        ])

        return headerStack
    }

    private func makeMetadataView() -> NSView {
        let publisherLabel = NSTextField(
            wrappingLabelWithString: String(
                format: BTLocalization.Settings.About.publisherFormat,
                BTAboutInfo.publisherName
            )
        )
        let metadataStack = NSStackView(views: [publisherLabel])
        metadataStack.orientation = .vertical
        metadataStack.alignment = .leading
        metadataStack.spacing = 0

        NSLayoutConstraint.activate([
            publisherLabel.widthAnchor.constraint(
                equalTo: metadataStack.widthAnchor
            ),
        ])

        return metadataStack
    }

    private func makeAttributionTitle() -> NSView {
        let label = NSTextField(
            labelWithString: BTLocalization.Settings.About.attributionTitle
        )
        label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        return label
    }

    private func makeAttributionSummary() -> NSView {
        let label = NSTextField(
            wrappingLabelWithString:
                BTLocalization.Settings.About.attributionSummary
        )
        label.setContentCompressionResistancePriority(
            .required,
            for: .vertical
        )

        return label
    }

    private func makeActionView() -> NSView {
        let stack = NSStackView(views: [
            self.makeActionButton(
                title: BTLocalization.Settings.About.website,
                systemSymbolName: "safari",
                action: self.websiteAction
            ),
            self.makeActionButton(
                title: BTLocalization.Settings.About.privacy,
                systemSymbolName: "hand.raised",
                action: self.privacyAction
            ),
            self.makeActionButton(
                title: BTLocalization.Settings.About.license,
                systemSymbolName: "doc.text",
                action: self.licenseAction
            ),
        ])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8

        return stack
    }
}
