//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal struct BTAboutInfoViewFactory {
    static let contentSize = NSSize(width: 520, height: 300)

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
        let linksView = self.makeLinksView()
        let footerView = self.makeFooterView()
        let spacerView = NSView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        let stack = NSStackView(views: [
            self.makeHeaderView(),
            metadataView,
            linksView,
            spacerView,
            footerView,
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14

        NSLayoutConstraint.activate([
            metadataView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            linksView.widthAnchor.constraint(equalTo: stack.widthAnchor),
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
            labelWithString: self.info.versionText
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
        let copyrightLabel = NSTextField(
            wrappingLabelWithString: self.info.copyrightText
        )
        copyrightLabel.textColor = .secondaryLabelColor

        let metadataStack = NSStackView(views: [copyrightLabel])
        metadataStack.orientation = .vertical
        metadataStack.alignment = .leading
        metadataStack.spacing = 0

        NSLayoutConstraint.activate([
            copyrightLabel.widthAnchor.constraint(
                equalTo: metadataStack.widthAnchor
            ),
        ])

        return metadataStack
    }

    private func makeLinksView() -> NSView {
        let stack = NSStackView(views: [
            self.makeTextLinkRow(
                title: BTLocalization.Settings.About.website,
                action: self.websiteAction
            ),
            self.makeTextLinkRow(
                title: BTLocalization.Settings.About.privacy,
                action: self.privacyAction
            ),
            self.makeTextLinkRow(
                title: BTLocalization.Settings.About.licenses,
                action: self.licenseAction
            ),
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6

        return stack
    }
}
