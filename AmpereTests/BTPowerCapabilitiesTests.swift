//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTPowerCapabilitiesTests: XCTestCase {
    func testFirmwareManagedCapabilitiesPreserveMagSafeSupport() throws {
        let capabilities = BTPowerCapabilities.firmwareManaged(
            adapterControl: false,
            magSafeSync: true
        )

        XCTAssertEqual(
            try BTPowerCapabilities(payload: capabilities.payload),
            capabilities
        )
        XCTAssertTrue(capabilities.magSafeSync)
        XCTAssertFalse(capabilities.directChargingControl)
    }
}
