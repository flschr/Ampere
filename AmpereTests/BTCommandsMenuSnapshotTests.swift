//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTCommandsMenuSnapshotTests: XCTestCase {
    private let settings = try! BTBatterySettings(
        minCharge: 70,
        maxCharge: 80,
        adapterSleep: false,
        magSafeSync: nil
    )

    func testPausedStateShowsResumeOnly() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(enabled: false),
            settings: self.settings,
            timeToEmptyEstimate: nil,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.paused.isHidden)
        XCTAssertFalse(snapshot.resumeActivity.isHidden)
        XCTAssertTrue(snapshot.pauseActivity.isHidden)
        XCTAssertTrue(snapshot.disablePowerAdapter.isHidden)
    }

    func testConnectedChargingToLimitShowsImmediateActions() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                connected: true,
                chargingDisabled: false,
                batteryPercent: 60,
                progress: .belowMax,
                chargingMode: .standard,
                maxCharge: 80
            ),
            settings: self.settings,
            timeToEmptyEstimate: nil,
            timeToFullEstimate: 7200
        )

        XCTAssertFalse(snapshot.powerAdapterEnabled.isHidden)
        XCTAssertFalse(snapshot.chargingToLimit.isHidden)
        XCTAssertFalse(snapshot.statusHeader.isHidden)
        XCTAssertTrue(snapshot.chargeToLimitNow.isHidden)
        XCTAssertFalse(snapshot.chargeToFullNow.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
        XCTAssertFalse(snapshot.remainingTime.isHidden)
    }

    func testConnectedHoldingChargeShowsOnlyImmediateLimitAction() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                connected: true,
                chargingDisabled: true,
                batteryPercent: 43,
                progress: .belowMax,
                chargingMode: .standard,
                maxCharge: 80
            ),
            settings: try! BTBatterySettings(
                minCharge: 50,
                maxCharge: 80,
                adapterSleep: false,
                magSafeSync: nil
            ),
            timeToEmptyEstimate: nil,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.powerAdapterEnabled.isHidden)
        XCTAssertFalse(snapshot.notCharging.isHidden)
        XCTAssertEqual(
            snapshot.statusHeader.title,
            "Charging paused until 49%"
        )
        XCTAssertFalse(snapshot.chargeToLimitNow.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
        XCTAssertTrue(snapshot.requestChargingToLimit.isHidden)
    }

    func testOnBatteryStandardModeShowsRequestActions() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                connected: false,
                chargingDisabled: true,
                batteryPercent: 76,
                progress: .belowFull,
                chargingMode: .standard,
                maxCharge: 80
            ),
            settings: self.settings,
            timeToEmptyEstimate: 3600,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.notCharging.isHidden)
        XCTAssertTrue(
            snapshot.statusHeader.title?.contains("until 70%") == true
        )
        XCTAssertTrue(
            snapshot.statusHeader.title?
                .contains("Charging paused until 69%") == true
        )
        XCTAssertFalse(snapshot.requestChargingToFull.isHidden)
        XCTAssertTrue(snapshot.requestChargingToLimit.isHidden)
        XCTAssertTrue(snapshot.cancelChargingRequest.isHidden)
        XCTAssertFalse(snapshot.remainingTime.isHidden)
    }

    func testDisconnectedPowerDoesNotShowUsingPowerAdapter() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                powerDisabled: false,
                connected: false,
                chargingDisabled: true,
                batteryPercent: 47,
                progress: .belowMax,
                chargingMode: .standard,
                maxCharge: 80
            ),
            settings: try! BTBatterySettings(
                minCharge: 50,
                maxCharge: 80,
                adapterSleep: false,
                magSafeSync: nil
            ),
            timeToEmptyEstimate: 7200,
            timeToFullEstimate: nil
        )

        XCTAssertTrue(snapshot.powerAdapterEnabled.isHidden)
        XCTAssertFalse(snapshot.powerAdapterDisabled.isHidden)
        XCTAssertFalse(snapshot.requestChargingToFull.isHidden)
        XCTAssertFalse(snapshot.requestChargingToLimit.isHidden)
        XCTAssertTrue(snapshot.chargeToFullNow.isHidden)
        XCTAssertTrue(snapshot.chargeToLimitNow.isHidden)
    }

    func testOnBatteryRequestedFullShowsCancelAndLimitRequest() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                connected: false,
                chargingDisabled: true,
                batteryPercent: 70,
                progress: .belowMax,
                chargingMode: .toFull,
                maxCharge: 80
            ),
            settings: self.settings,
            timeToEmptyEstimate: nil,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.requestedChargingToFull.isHidden)
        XCTAssertFalse(snapshot.requestChargingToLimit.isHidden)
        XCTAssertFalse(snapshot.cancelChargingRequest.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
    }
}
