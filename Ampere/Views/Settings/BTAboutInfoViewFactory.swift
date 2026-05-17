//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal struct BTAboutInfoViewFactory {
    static let contentSize = NSSize(width: 460, height: 270)

    let info: BTAboutInfo
    let target: AnyObject
    let websiteAction: Selector
    let privacyAction: Selector
    let licenseAction: Selector
    let updateAction: Selector
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
        let bodyView = self.makeBodyView()
        let footerView = self.makeFooterView()
        let spacerView = NSView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        let stack = NSStackView(views: [
            bodyView,
            spacerView,
            footerView,
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18

        NSLayoutConstraint.activate([
            bodyView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            footerView.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        return stack
    }

    private func makeBodyView() -> NSView {
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

        let titleStack = NSStackView(views: [appNameLabel, versionLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let detailStack = NSStackView(views: [
            titleStack,
            self.makeLinksView(),
        ])
        detailStack.orientation = .vertical
        detailStack.alignment = .leading
        detailStack.spacing = 14

        let bodyStack = NSStackView(views: [iconView, detailStack])
        bodyStack.orientation = .horizontal
        bodyStack.alignment = .top
        bodyStack.spacing = 16

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
        ])

        return bodyStack
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
            self.makeTextLinkRow(
                title: BTLocalization.Settings.About.checkForUpdates,
                action: self.updateAction
            ),
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 5

        return stack
    }
}
