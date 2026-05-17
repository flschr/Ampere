//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

#if !OFFICIAL_BUILD
    internal enum BTLicenseManagerFactory {
        static func make() -> any BTLicenseManaging {
            BTSourceBuildLicenseManager()
        }
    }
#endif
