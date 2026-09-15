//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTError: UInt8, Error {
    case success
    case unknown
    case notAuthorized
    case commFailed
    case malformedData
    case unsupported

    init(daemonRawValue rawValue: RawValue) {
        // Older installed daemons may return status values that no longer exist
        // in the current app. Treat them as unknown during daemon replacement.
        self = Self(rawValue: rawValue) ?? .unknown
    }

    init(fromBool: Bool) {
        self = fromBool ? .success : .unknown
    }
}
