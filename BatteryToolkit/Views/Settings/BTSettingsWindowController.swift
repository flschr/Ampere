//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit
import Foundation

@MainActor
internal final class BTSettingsWindowController: NSWindowController {
    private static let contentSize = NSSize(width: 520, height: 520)

    @IBOutlet private var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.contentMinSize = Self.contentSize
        self.window?.contentMaxSize = Self.contentSize
        self.window?.setContentSize(Self.contentSize)
        self.window?.toolbar = nil
        self.window?.title = Self.appName
    }

    override func close() {
        super.close()
    }

    @IBAction private func userAction(_ sender: NSToolbarItem) {
        self.window?.title = Self.appName
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
