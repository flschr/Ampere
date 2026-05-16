//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTBatteryModelsTests: XCTestCase {
    func testBatteryStateRoundTripsEnabledPayload() throws {
        let state = BTBatteryState(
            enabled: true,
            powerDisabled: true,
            connected: false,
            chargingDisabled: true,
            batteryPercent: 64,
            progress: .belowFull,
            chargingMode: .toFull,
            maxCharge: 90
        )

        XCTAssertEqual(try BTBatteryState(payload: state.payload), state)
    }

    func testBatteryStateAllowsPausedPayloadWithoutPowerValues() throws {
        let payload: [String: NSObject & Sendable] = [
            BTStateInfo.Keys.enabled: NSNumber(value: false)
        ]

        let state = try BTBatteryState(payload: payload)

        XCTAssertEqual(state, BTBatteryState(enabled: false))
        XCTAssertEqual(state.payload.count, 1)
    }

    func testBatteryStateRejectsMalformedEnabledPayload() {
        XCTAssertThrowsError(try BTBatteryState(payload: [:])) { error in
            XCTAssertEqual(error as? BTError, .malformedData)
        }
    }

    func testBatteryStateRejectsUnknownEnumRawValues() {
        let payload: [String: NSObject & Sendable] = [
            BTStateInfo.Keys.enabled: NSNumber(value: true),
            BTStateInfo.Keys.powerDisabled: NSNumber(value: false),
            BTStateInfo.Keys.connected: NSNumber(value: true),
            BTStateInfo.Keys.chargingDisabled: NSNumber(value: false),
            BTStateInfo.Keys.batteryPercent: NSNumber(value: 50),
            BTStateInfo.Keys.progress: NSNumber(value: 99),
            BTStateInfo.Keys.chargingMode: NSNumber(
                value: BTStateInfo.ChargingMode.standard.rawValue
            ),
            BTStateInfo.Keys.maxCharge: NSNumber(value: 80),
        ]

        XCTAssertThrowsError(try BTBatteryState(payload: payload)) { error in
            XCTAssertEqual(error as? BTError, .malformedData)
        }
    }

    func testBatterySettingsRoundTripsWithMagSafeSupport() throws {
        let settings = try BTBatterySettings(
            minCharge: 70,
            maxCharge: 85,
            adapterSleep: true,
            magSafeSync: false
        )

        XCTAssertEqual(try BTBatterySettings(payload: settings.payload), settings)
    }

    func testBatterySettingsRoundTripsWithoutMagSafeSupport() throws {
        let settings = try BTBatterySettings(
            minCharge: 75,
            maxCharge: 80,
            adapterSleep: false,
            magSafeSync: nil
        )

        let parsed = try BTBatterySettings(payload: settings.payload)

        XCTAssertEqual(parsed, settings)
        XCTAssertNil(parsed.payload[BTSettingsInfo.Keys.magSafeSync])
    }

    func testBatterySettingsRejectsInvalidChargeLimits() {
        XCTAssertThrowsError(
            try BTBatterySettings(
                minCharge: 90,
                maxCharge: 80,
                adapterSleep: false,
                magSafeSync: nil
            )
        ) { error in
            XCTAssertEqual(error as? BTError, .malformedData)
        }
    }

    func testBatterySettingsRejectsMissingRequiredValues() {
        let payload: [String: NSObject & Sendable] = [
            BTSettingsInfo.Keys.minCharge: NSNumber(value: 75),
            BTSettingsInfo.Keys.maxCharge: NSNumber(value: 80),
        ]

        XCTAssertThrowsError(try BTBatterySettings(payload: payload)) { error in
            XCTAssertEqual(error as? BTError, .malformedData)
        }
    }
}
