//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTSettingsModelTests: XCTestCase {
    func testChargeLimitDraftClampsMinCharge() {
        var draft = BTChargeLimitDraft(minCharge: 70, maxCharge: 80)

        draft.setMinCharge(10)
        XCTAssertEqual(draft.minCharge, BTSettingsInfo.Bounds.minChargeMin)

        draft.setMinCharge(120)
        XCTAssertEqual(draft.minCharge, 100)
        XCTAssertEqual(draft.maxCharge, 100)
    }

    func testChargeLimitDraftClampsMaxCharge() {
        var draft = BTChargeLimitDraft(minCharge: 70, maxCharge: 80)

        draft.setMaxCharge(10)
        XCTAssertEqual(draft.maxCharge, BTSettingsInfo.Bounds.maxChargeMin)
        XCTAssertEqual(draft.minCharge, BTSettingsInfo.Bounds.maxChargeMin)

        draft.setMaxCharge(120)
        XCTAssertEqual(draft.maxCharge, 100)
    }

    func testSettingsPayloadFactoryRetiresObsoleteControls() throws {
        let payload = try BTSettingsPayloadFactory.make(
            minCharge: 70,
            maxCharge: 80,
        )

        XCTAssertEqual((payload[BTSettingsInfo.Keys.magSafeSync] as? NSNumber)?.boolValue, false)
        XCTAssertEqual((payload[BTSettingsInfo.Keys.adapterSleep] as? NSNumber)?.boolValue, true)
    }

    func testSettingsPayloadFactoryDetectsChangedPayload() throws {
        let current = try BTSettingsPayloadFactory.make(
            minCharge: 70,
            maxCharge: 80,
        )
        let changed = try BTSettingsPayloadFactory.make(
            minCharge: 70,
            maxCharge: 85,
        )

        XCTAssertFalse(BTSettingsPayloadFactory.changed(current, from: current))
        XCTAssertTrue(BTSettingsPayloadFactory.changed(changed, from: current))
    }
}
