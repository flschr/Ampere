//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal struct BTSourceBuildLicenseManager: BTLicenseManaging {
    func currentStatus() -> BTLicenseStatus {
        .sourceBuild
    }
}
