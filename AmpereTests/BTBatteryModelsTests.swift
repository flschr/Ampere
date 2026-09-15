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
            maxCharge: 90,
            thermallyLimited: true
        )

        XCTAssertEqual(try BTBatteryState(payload: state.payload), state)
    }

    func testBatteryStateDefaultsMissingThermalLimitToFalse() throws {
        let payload: [String: NSObject & Sendable] = [
            BTStateInfo.Keys.enabled: NSNumber(value: true),
            BTStateInfo.Keys.powerDisabled: NSNumber(value: false),
            BTStateInfo.Keys.connected: NSNumber(value: true),
            BTStateInfo.Keys.chargingDisabled: NSNumber(value: false),
            BTStateInfo.Keys.batteryPercent: NSNumber(value: 50),
            BTStateInfo.Keys.progress: NSNumber(
                value: BTStateInfo.ChargingProgress.belowMax.rawValue
            ),
            BTStateInfo.Keys.chargingMode: NSNumber(
                value: BTStateInfo.ChargingMode.standard.rawValue
            ),
            BTStateInfo.Keys.maxCharge: NSNumber(value: 80),
        ]

        let state = try BTBatteryState(payload: payload)

        XCTAssertFalse(state.thermallyLimited)
        XCTAssertEqual(state.capabilities, .legacy)
    }

    func testBatteryStateUsesPowerAdapterOnlyWhenConnectedAndEnabled() {
        XCTAssertTrue(
            BTBatteryState(enabled: true, connected: true).usesPowerAdapter
        )
        XCTAssertFalse(
            BTBatteryState(enabled: true, powerDisabled: true, connected: true)
                .usesPowerAdapter
        )
        XCTAssertFalse(
            BTBatteryState(enabled: true, connected: false).usesPowerAdapter
        )
        XCTAssertFalse(
            BTBatteryState(enabled: false, connected: true).usesPowerAdapter
        )
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

    func testSystemManagedCapabilitiesRoundTrip() throws {
        let capabilities = try XCTUnwrap(
            BTPowerCapabilities.systemManaged(
                adapterControl: true,
                availableLimits: [100, 80, 90, 85, 95]
            )
        )
        let settings = try BTBatterySettings(
            minCharge: 70,
            maxCharge: 85,
            adapterSleep: false,
            magSafeSync: nil,
            capabilities: capabilities
        )

        XCTAssertEqual(
            try BTBatterySettings(payload: settings.payload).capabilities,
            capabilities
        )
        XCTAssertTrue(capabilities.supports(maxCharge: 90))
        XCTAssertFalse(capabilities.supports(maxCharge: 91))
        XCTAssertEqual(capabilities.nearestSupported(maxCharge: 92), 90)
        XCTAssertEqual(capabilities.nearestSupported(maxCharge: 79), 80)
    }

    func testCapabilitiesRejectMalformedPayload() {
        var payload = BTPowerCapabilities.legacy.payload
        payload[BTPowerCapabilities.Keys.maxChargeStep] = NSNumber(value: 0)

        XCTAssertThrowsError(try BTPowerCapabilities(payload: payload)) {
            error in
            XCTAssertEqual(error as? BTError, .malformedData)
        }
    }

    func testSystemCapabilitiesRejectIrregularLimits() {
        XCTAssertNil(
            BTPowerCapabilities.systemManaged(
                adapterControl: false,
                availableLimits: [80, 85, 95, 100]
            )
        )
    }
}
