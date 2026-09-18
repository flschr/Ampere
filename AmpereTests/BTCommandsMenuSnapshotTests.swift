//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTCommandsMenuSnapshotTests: XCTestCase {
    private let settings = try! BTBatterySettings(
        minCharge: 70,
        maxCharge: 80,
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
        XCTAssertFalse(snapshot.disablePowerAdapter.isHidden)
        XCTAssertEqual(snapshot.disablePowerAdapter.stateOn, true)
        XCTAssertTrue(snapshot.disablePowerAdapter.isEnabled)
        XCTAssertFalse(snapshot.chargingToLimit.isHidden)
        XCTAssertFalse(snapshot.statusHeader.isHidden)
        XCTAssertEqual(snapshot.statusHeader.title, "Charging to 80%")
        XCTAssertTrue(snapshot.chargeToLimitNow.isHidden)
        XCTAssertFalse(snapshot.chargeToFullNow.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
        XCTAssertFalse(snapshot.remainingTime.isHidden)
    }

    func testConnectedHoldingChargeShowsPowerAdapterAndHeldLimit() {
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
            ),
            timeToEmptyEstimate: nil,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.powerAdapterEnabled.isHidden)
        XCTAssertFalse(snapshot.disablePowerAdapter.isHidden)
        XCTAssertEqual(snapshot.disablePowerAdapter.stateOn, true)
        XCTAssertTrue(snapshot.disablePowerAdapter.isEnabled)
        XCTAssertTrue(snapshot.notCharging.isHidden)
        XCTAssertFalse(snapshot.statusDetail.isHidden)
        XCTAssertFalse(snapshot.statusSubdetail.isHidden)
        XCTAssertEqual(
            snapshot.statusHeader.title,
            "MacBook is powered by the power adapter"
        )
        XCTAssertEqual(
            snapshot.statusDetail.title,
            "Battery is not actively charging or discharging"
        )
        XCTAssertEqual(
            snapshot.statusSubdetail.title,
            "Charge limit 80% is active"
        )
        XCTAssertFalse(snapshot.chargeToLimitNow.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
        XCTAssertTrue(snapshot.requestChargingToLimit.isHidden)
    }

    func testThermalLimitShowsHotBatteryStatus() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                connected: true,
                chargingDisabled: true,
                batteryPercent: 75,
                progress: .belowMax,
                chargingMode: .toFull,
                maxCharge: 80,
                thermallyLimited: true
            ),
            settings: self.settings,
            timeToEmptyEstimate: nil,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.notCharging.isHidden)
        XCTAssertEqual(
            snapshot.statusHeader.title,
            "Charging paused: battery too warm"
        )
    }

    func testDisconnectedBatteryStandardModeShowsAdapterRequirement() {
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

        XCTAssertTrue(snapshot.notCharging.isHidden)
        XCTAssertFalse(snapshot.statusDetail.isHidden)
        XCTAssertEqual(
            snapshot.statusHeader.title,
            "MacBook is powered by the battery"
        )
        XCTAssertEqual(
            snapshot.statusDetail.title,
            "Charges again below 70% when a power adapter is connected"
        )
        XCTAssertTrue(snapshot.remainingTime.title?.contains("until 70%") == true)
        XCTAssertFalse(snapshot.requestChargingToFull.isHidden)
        XCTAssertFalse(snapshot.requestChargingToFull.isEnabled)
        XCTAssertTrue(snapshot.requestChargingToLimit.isHidden)
        XCTAssertTrue(snapshot.cancelChargingRequest.isHidden)
        XCTAssertFalse(snapshot.remainingTime.isHidden)
    }

    func testConnectedBatteryStandardModeShowsResumeThreshold() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                powerDisabled: true,
                connected: true,
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

        XCTAssertFalse(snapshot.powerAdapterDisabled.isHidden)
        XCTAssertFalse(snapshot.enablePowerAdapter.isHidden)
        XCTAssertEqual(snapshot.enablePowerAdapter.stateOn, false)
        XCTAssertTrue(snapshot.enablePowerAdapter.isEnabled)
        XCTAssertTrue(snapshot.notCharging.isHidden)
        XCTAssertFalse(snapshot.statusDetail.isHidden)
        XCTAssertEqual(
            snapshot.statusHeader.title,
            "MacBook is powered by the battery"
        )
        XCTAssertEqual(
            snapshot.statusDetail.title,
            "Charging resumes below 70%"
        )
        XCTAssertTrue(snapshot.remainingTime.title?.contains("until 70%") == true)
    }

    func testConnectedBatteryBelowThresholdShowsPowerAdapterRequirement() {
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                powerDisabled: true,
                connected: true,
                chargingDisabled: true,
                batteryPercent: 47,
                progress: .belowMax,
                chargingMode: .standard,
                maxCharge: 80
            ),
            settings: try! BTBatterySettings(
                minCharge: 50,
                maxCharge: 80,
            ),
            timeToEmptyEstimate: 7200,
            timeToFullEstimate: nil
        )

        XCTAssertFalse(snapshot.enablePowerAdapter.isHidden)
        XCTAssertTrue(snapshot.enablePowerAdapter.isEnabled)
        XCTAssertEqual(
            snapshot.statusDetail.title,
            "Charges when the power adapter is used"
        )
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
            ),
            timeToEmptyEstimate: 7200,
            timeToFullEstimate: nil
        )

        XCTAssertTrue(snapshot.powerAdapterEnabled.isHidden)
        XCTAssertFalse(snapshot.powerAdapterDisabled.isHidden)
        XCTAssertFalse(snapshot.disablePowerAdapter.isHidden)
        XCTAssertEqual(snapshot.disablePowerAdapter.stateOn, false)
        XCTAssertFalse(snapshot.disablePowerAdapter.isEnabled)
        XCTAssertTrue(snapshot.enablePowerAdapter.isHidden)
        XCTAssertFalse(snapshot.requestChargingToFull.isHidden)
        XCTAssertFalse(snapshot.requestChargingToLimit.isHidden)
        XCTAssertFalse(snapshot.requestChargingToFull.isEnabled)
        XCTAssertFalse(snapshot.requestChargingToLimit.isEnabled)
        XCTAssertEqual(
            snapshot.statusDetail.title,
            "Charges when a power adapter is connected"
        )
        XCTAssertEqual(
            snapshot.requestChargingToLimit.title,
            "Request Charging to 80%"
        )
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
        XCTAssertFalse(snapshot.requestChargingToLimit.isEnabled)
        XCTAssertFalse(snapshot.cancelChargingRequest.isHidden)
        XCTAssertTrue(snapshot.requestChargingToFull.isHidden)
    }

    func testSystemManagedModeHidesUnsupportedDirectControls() throws {
        let capabilities = try XCTUnwrap(
            BTPowerCapabilities.systemManaged(
                adapterControl: false,
                availableLimits: [80, 85, 90, 95, 100]
            )
        )
        let snapshot = BTCommandsMenuSnapshotFactory.make(
            state: BTBatteryState(
                enabled: true,
                connected: true,
                chargingDisabled: false,
                batteryPercent: 75,
                progress: .belowMax,
                maxCharge: 80,
                capabilities: capabilities
            ),
            settings: self.settings,
            timeToEmptyEstimate: nil,
            timeToFullEstimate: nil
        )

        XCTAssertTrue(snapshot.disableCharging.isHidden)
        XCTAssertTrue(snapshot.disablePowerAdapter.isHidden)
        XCTAssertTrue(snapshot.enablePowerAdapter.isHidden)
        XCTAssertFalse(snapshot.chargeToFullNow.isHidden)
    }
}
