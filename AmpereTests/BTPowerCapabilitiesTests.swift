//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTPowerCapabilitiesTests: XCTestCase {
    func testSystemManagedModeLeavesMagSafeToMacOS() throws {
        let capabilities = try XCTUnwrap(
            BTPowerCapabilities.systemManaged(
                adapterControl: true,
                availableLimits: [80, 85, 90, 95, 100]
            )
        )

        XCTAssertFalse(capabilities.magSafeSync)
        XCTAssertEqual(
            try BTPowerCapabilities(payload: capabilities.payload),
            capabilities
        )

        var inconsistentPayload = capabilities.payload
        inconsistentPayload[BTPowerCapabilities.Keys.magSafeSync] = NSNumber(
            value: true
        )
        XCTAssertThrowsError(
            try BTPowerCapabilities(payload: inconsistentPayload)
        )
    }

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
