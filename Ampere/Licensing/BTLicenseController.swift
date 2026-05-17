//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLicenseController {
    static let shared = BTLicenseManagerFactory.make()

    static func currentStatus() -> BTLicenseStatus {
        self.shared.currentStatus()
    }

    static func requireCanManageCharging() throws {
        let status = self.currentStatus()
        guard status.canManageCharging else {
            throw BTError.licenseRequired
        }
    }
}
