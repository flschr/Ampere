//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTSettingsModelTests: XCTestCase {
    func testChargeLimitDraftClampsMinCharge() {
        var draft = BTChargeLimitDraft(minCharge: 75, maxCharge: 80)

        draft.setMinCharge(10)
        XCTAssertEqual(draft.minCharge, BTSettingsInfo.Bounds.minChargeMin)

        draft.setMinCharge(120)
        XCTAssertEqual(draft.minCharge, 100)
        XCTAssertEqual(draft.maxCharge, 100)
    }

    func testChargeLimitDraftClampsMaxCharge() {
        var draft = BTChargeLimitDraft(minCharge: 75, maxCharge: 80)

        draft.setMaxCharge(10)
        XCTAssertEqual(draft.maxCharge, BTSettingsInfo.Bounds.maxChargeMin)
        XCTAssertEqual(draft.minCharge, BTSettingsInfo.Bounds.maxChargeMin)

        draft.setMaxCharge(120)
        XCTAssertEqual(draft.maxCharge, 100)
    }

    func testMatchingPreset() {
        XCTAssertEqual(
            BTChargePreset.matching(minCharge: 70, maxCharge: 80),
            .everyday
        )
        XCTAssertEqual(
            BTChargePreset.matching(minCharge: 50, maxCharge: 80),
            .desk
        )
        XCTAssertEqual(
            BTChargePreset.matching(minCharge: 80, maxCharge: 90),
            .travel
        )
        XCTAssertNil(BTChargePreset.matching(minCharge: 75, maxCharge: 80))
    }

    func testSettingsPayloadFactoryOmitsUnsupportedMagSafe() throws {
        let payload = try BTSettingsPayloadFactory.make(
            minCharge: 75,
            maxCharge: 80,
            adapterSleep: false,
            magSafeSync: nil
        )

        XCTAssertNil(payload[BTSettingsInfo.Keys.magSafeSync])
        XCTAssertFalse(
            try BTBatterySettings(payload: payload).adapterSleep
        )
    }

    func testSettingsPayloadFactoryDetectsChangedPayload() throws {
        let current = try BTSettingsPayloadFactory.make(
            minCharge: 75,
            maxCharge: 80,
            adapterSleep: false,
            magSafeSync: true
        )
        let changed = try BTSettingsPayloadFactory.make(
            minCharge: 70,
            maxCharge: 80,
            adapterSleep: false,
            magSafeSync: true
        )

        XCTAssertFalse(BTSettingsPayloadFactory.changed(current, from: current))
        XCTAssertTrue(BTSettingsPayloadFactory.changed(changed, from: current))
    }
}
