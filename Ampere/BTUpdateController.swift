//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import Sparkle

@MainActor
internal final class BTUpdateController: NSObject {
    static let shared = BTUpdateController()

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private override init() {
        super.init()
    }

    func start() {
        guard self.isConfigured else {
            return
        }

        _ = self.updaterController
    }

    func checkForUpdates(_ sender: Any?) {
        guard self.isConfigured else {
            self.presentConfigurationError()
            return
        }

        self.updaterController.checkForUpdates(sender)
    }

    private var isConfigured: Bool {
        self.infoValue(for: "SUFeedURL") != nil &&
            self.infoValue(for: "SUPublicEDKey") != nil
    }

    private func infoValue(for key: String) -> String? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: key
        ) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }

        return trimmed
    }

    private func presentConfigurationError() {
        let alert = NSAlert()
        alert.messageText =
            BTLocalization.Settings.About.updateUnavailableMessage
        alert.informativeText =
            BTLocalization.Settings.About.updateUnavailableInfo
        alert.addButton(withTitle: BTLocalization.Prompts.ok)

        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
