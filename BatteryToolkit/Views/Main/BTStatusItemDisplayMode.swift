//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTStatusItemDisplayMode: Int, CaseIterable {
    case iconOnly = 0
    case percentInIcon = 1
    case percentOnly = 2
    case hidden = 3

    static let defaultsKey = "StatusItemDisplayMode"
    static let didChangeNotification = Notification.Name(
        "BTStatusItemDisplayModeDidChange"
    )

    var title: String {
        switch self {
        case .iconOnly:
            return BTLocalization.Settings.StatusItem.iconOnly
        case .percentInIcon:
            return BTLocalization.Settings.StatusItem.percentInIcon
        case .percentOnly:
            return BTLocalization.Settings.StatusItem.percentOnly
        case .hidden:
            return BTLocalization.Settings.StatusItem.hidden
        }
    }

    static var current: BTStatusItemDisplayMode {
        get {
            let value = UserDefaults.standard.integer(forKey: self.defaultsKey)
            return BTStatusItemDisplayMode(rawValue: value) ?? .percentInIcon
        }

        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: self.defaultsKey)
            NotificationCenter.default.post(
                name: self.didChangeNotification,
                object: nil
            )
        }
    }
}
