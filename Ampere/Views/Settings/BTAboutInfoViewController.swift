//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal final class BTAboutInfoViewController: NSViewController {
    private let info: BTAboutInfo

    init(info: BTAboutInfo = .current) {
        self.info = info
        super.init(nibName: nil, bundle: nil)
        self.preferredContentSize = BTAboutInfoViewFactory.contentSize
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        self.view = BTAboutInfoViewFactory(
            info: self.info,
            target: self,
            websiteAction: #selector(self.websiteButtonAction(_:)),
            privacyAction: #selector(self.privacyButtonAction(_:)),
            licenseAction: #selector(self.licenseButtonAction(_:)),
            updateAction: #selector(self.updateButtonAction(_:)),
            uninstallAction: #selector(self.uninstallButtonAction(_:)),
            closeAction: #selector(self.closeButtonAction(_:))
        ).makeView()
    }

    @objc private func websiteButtonAction(_: NSButton) {
        NSWorkspace.shared.open(BTAboutInfo.websiteURL)
    }

    @objc private func privacyButtonAction(_: NSButton) {
        NSWorkspace.shared.open(BTAboutInfo.privacyURL)
    }

    @objc private func licenseButtonAction(_: NSButton) {
        self.presentAsSheet(BTLicenseViewController())
    }

    @objc private func updateButtonAction(_ sender: NSButton) {
        BTUpdateController.shared.checkForUpdates(sender)
    }

    @objc private func uninstallButtonAction(_: NSButton) {
        let presentingWindow = self.view.window?.sheetParent ?? self.view.window
        self.close()

        Task {
            await BTAppPrompts.promptRemoveDaemonAndAppData(
                window: presentingWindow
            )
        }
    }

    @objc private func closeButtonAction(_: NSButton) {
        self.close()
    }

    private func close() {
        if self.view.window?.sheetParent != nil {
            self.dismiss(nil)
        } else {
            self.view.window?.close()
        }
    }
}
