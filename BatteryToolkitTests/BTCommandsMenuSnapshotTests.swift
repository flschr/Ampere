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
        XCTAssertTrue(snapshot.chargeToLimitNow.isHidden)
        XCTAssertFalse(snapshot.chargeToFullNow.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
        XCTAssertFalse(snapshot.remainingTime.isHidden)
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
        XCTAssertFalse(snapshot.requestChargingToFull.isHidden)
        XCTAssertTrue(snapshot.requestChargingToLimit.isHidden)
        XCTAssertTrue(snapshot.cancelChargingRequest.isHidden)
        XCTAssertFalse(snapshot.remainingTime.isHidden)
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
