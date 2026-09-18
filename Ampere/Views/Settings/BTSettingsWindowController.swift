//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit
import Foundation

@MainActor
internal final class BTSettingsWindowController: NSWindowController {
    @IBOutlet private var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.contentMinSize = BTSettingsViewController.contentSize
        self.window?.contentMaxSize = BTSettingsViewController.contentSize
        self.window?.setContentSize(BTSettingsViewController.contentSize)
        self.window?.toolbar = nil
        self.window?.title = Self.appName
    }

    override func close() {
        super.close()
    }

    @IBAction private func powerAction(_ sender: NSToolbarItem) {
        self.window?.title = Self.appName
    }

    private static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
            as? String ??
            Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
            as? String ??
            "Ampere"
    }
}
