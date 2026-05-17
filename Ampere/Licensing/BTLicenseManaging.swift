//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLicenseStatus: Equatable, Sendable {
    case sourceBuild
    case trial(daysRemaining: Int)
    case licensed
    case expired

    var canManageCharging: Bool {
        switch self {
        case .sourceBuild, .trial, .licensed:
            return true
        case .expired:
            return false
        }
    }
}

internal protocol BTLicenseManaging: Sendable {
    func currentStatus() -> BTLicenseStatus
}
