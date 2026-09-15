//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTBuildKind: Equatable, Sendable {
    case source
    case official

    var localizedName: String {
        switch self {
        case .source:
            return BTLocalization.Settings.About.sourceBuild
        case .official:
            return BTLocalization.Settings.About.officialBuild
        }
    }
}

internal enum BTBuildConfiguration {
    #if OFFICIAL_BUILD
        static let kind = BTBuildKind.official
    #else
        static let kind = BTBuildKind.source
    #endif

    static var isOfficialBuild: Bool {
        self.kind == .official
    }

    static var allowsOfficialUpdates: Bool {
        self.isOfficialBuild
    }
}
