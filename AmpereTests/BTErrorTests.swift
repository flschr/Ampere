//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTErrorTests: XCTestCase {
    func testDaemonRawValueMapsKnownErrors() {
        XCTAssertEqual(
            BTError(daemonRawValue: BTError.notAuthorized.rawValue),
            .notAuthorized
        )
    }

    func testDaemonRawValueMapsLegacyUnknownErrorsToUnknown() {
        XCTAssertEqual(BTError(daemonRawValue: 6), .unknown)
    }
}
