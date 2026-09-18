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

        XCTAssertEqual((capabilities.payload[BTPowerCapabilities.Keys.magSafeSync] as? NSNumber)?.boolValue, false)
        XCTAssertEqual(
            try BTPowerCapabilities(payload: capabilities.payload),
            capabilities
        )

        var inconsistentPayload = capabilities.payload
        inconsistentPayload[BTPowerCapabilities.Keys.magSafeSync] = NSNumber(
            value: true
        )
        XCTAssertEqual(try BTPowerCapabilities(payload: inconsistentPayload), capabilities)
    }

    func testFirmwareManagedCapabilitiesDoNotExposeMagSafeOverride() throws {
        let capabilities = BTPowerCapabilities.firmwareManaged(
            adapterControl: false
        )

        XCTAssertEqual(
            try BTPowerCapabilities(payload: capabilities.payload),
            capabilities
        )
        XCTAssertEqual((capabilities.payload[BTPowerCapabilities.Keys.magSafeSync] as? NSNumber)?.boolValue, false)
        XCTAssertFalse(capabilities.directChargingControl)
    }
}
