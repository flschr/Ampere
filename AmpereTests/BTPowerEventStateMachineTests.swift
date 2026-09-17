//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTPowerEventStateMachineTests: XCTestCase {
    func testHysteresisDisablesChargingAtMaxInStandardMode() {
        XCTAssertEqual(
            BTPowerEventStateMachine.hysteresisEffect(
                percent: 80,
                minCharge: 70,
                maxCharge: 80,
                chargingMode: .standard
            ),
            .disableCharging
        )
    }

    func testHysteresisEnablesChargingBelowMin() {
        XCTAssertEqual(
            BTPowerEventStateMachine.hysteresisEffect(
                percent: 69,
                minCharge: 70,
                maxCharge: 80,
                chargingMode: .standard
            ),
            .enableCharging
        )
    }

    func testChargeToFullDoesNotDisableAtChargeLimit() {
        XCTAssertEqual(
            BTPowerEventStateMachine.hysteresisEffect(
                percent: 80,
                minCharge: 70,
                maxCharge: 80,
                chargingMode: .toFull
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.hysteresisEffect(
                percent: 100,
                minCharge: 70,
                maxCharge: 80,
                chargingMode: .toFull
            ),
            .disableCharging
        )
    }

    func testPendingChargeModeEffectsOnReplug() {
        XCTAssertEqual(
            BTPowerEventStateMachine.pendingModeEffect(
                percent: 79,
                chargingMode: .toLimit,
                maxCharge: 80
            ),
            .enableCharging
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.pendingModeEffect(
                percent: 80,
                chargingMode: .toLimit,
                maxCharge: 80
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.pendingModeEffect(
                percent: 99,
                chargingMode: .toFull,
                maxCharge: 80
            ),
            .enableCharging
        )
    }

    func testBelowLimitModeEffect() {
        XCTAssertEqual(
            BTPowerEventStateMachine.belowLimitModeEffect(percent: 79, limit: 80),
            .enableCharging
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.belowLimitModeEffect(percent: 80, limit: 80),
            .none
        )
    }

    func testDisconnectedRecoveryEnablesBelowMinForStandardMode() {
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 49,
                minCharge: 50,
                chargingMode: .standard
            ),
            .enableCharging
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 50,
                minCharge: 50,
                chargingMode: .standard
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 80,
                minCharge: 50,
                chargingMode: .standard
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 49,
                minCharge: 50,
                chargingMode: .toFull
            ),
            .none
        )
    }

    func testDisconnectedBatteryMonitoringOnlyForStandardHold() {
        XCTAssertTrue(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingMode: .standard
            )
        )
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingMode: .toLimit
            )
        )
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingMode: .toFull
            )
        )
    }

    func testLowPowerThresholdKeepsMonitoringDuringChargeRequests() {
        XCTAssertTrue(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingMode: .toFull,
                lowPowerModeThreshold: 20
            )
        )
    }

    func testAutomaticLowPowerModeRequiresBatteryAndNonzeroThreshold() {
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldEnableLowPowerMode(
                percent: 0,
                threshold: 0,
                drawingUnlimitedPower: false
            )
        )
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldEnableLowPowerMode(
                percent: 20,
                threshold: 20,
                drawingUnlimitedPower: true
            )
        )
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldEnableLowPowerMode(
                percent: 21,
                threshold: 20,
                drawingUnlimitedPower: false
            )
        )
        XCTAssertTrue(
            BTPowerEventStateMachine.shouldEnableLowPowerMode(
                percent: 20,
                threshold: 20,
                drawingUnlimitedPower: false
            )
        )
    }

    func testThermalProtectionPausesHotActiveCharging() {
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalEffect(
                temperatureCelsius: 40,
                thermallyLimited: false,
                chargingDisabled: false,
                percent: 75,
                minCharge: 70,
                chargingMode: .standard
            ),
            .pauseCharging
        )
    }

    func testThermalProtectionBlocksExpectedChargingWhileAlreadyDisabled() {
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalEffect(
                temperatureCelsius: 41,
                thermallyLimited: false,
                chargingDisabled: true,
                percent: 69,
                minCharge: 70,
                chargingMode: .standard
            ),
            .pauseCharging
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalEffect(
                temperatureCelsius: 41,
                thermallyLimited: false,
                chargingDisabled: true,
                percent: 75,
                minCharge: 70,
                chargingMode: .standard
            ),
            .none
        )
    }

    func testThermalProtectionUsesRecoveryHysteresis() {
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalEffect(
                temperatureCelsius: 39,
                thermallyLimited: true,
                chargingDisabled: true,
                percent: 75,
                minCharge: 70,
                chargingMode: .standard
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalEffect(
                temperatureCelsius: 38,
                thermallyLimited: true,
                chargingDisabled: true,
                percent: 75,
                minCharge: 70,
                chargingMode: .standard
            ),
            .resumeCharging
        )
    }

    func testThermalProtectionResumesWhenTemperatureUnavailable() {
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalEffect(
                temperatureCelsius: nil,
                thermallyLimited: true,
                chargingDisabled: true,
                percent: 75,
                minCharge: 70,
                chargingMode: .toFull
            ),
            .resumeCharging
        )
    }

    func testThermalRecoveryResumesTowardRequestedTarget() {
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalRecoveryEffect(
                percent: 75,
                maxCharge: 80,
                chargingMode: .standard
            ),
            .enableCharging
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalRecoveryEffect(
                percent: 80,
                maxCharge: 80,
                chargingMode: .standard
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.thermalRecoveryEffect(
                percent: 99,
                maxCharge: 80,
                chargingMode: .toFull
            ),
            .enableCharging
        )
    }

    func testChargingSleepEffectBalancesSleepWithChargingState() {
        XCTAssertEqual(
            BTPowerEventStateMachine.chargingSleepEffect(chargingDisabled: true),
            .restoreSleep
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.chargingSleepEffect(chargingDisabled: false),
            .disableSleep
        )
    }

    func testPowerAdapterSleepEffectHonorsAdapterSleepSetting() {
        XCTAssertEqual(
            BTPowerEventStateMachine.powerAdapterSleepEffect(
                powerDisabled: true,
                adapterSleep: false
            ),
            .disableSleep
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.powerAdapterSleepEffect(
                powerDisabled: false,
                adapterSleep: false
            ),
            .restoreSleep
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.powerAdapterSleepEffect(
                powerDisabled: true,
                adapterSleep: true
            ),
            .none
        )
    }

    func testWakeFromSleepEffectsRefreshAndRestoreSleep() {
        XCTAssertEqual(
            BTPowerEventStateMachine.wakeFromSleepEffects(
                percentHandlerRegistered: true
            ),
            [
                .disableSleep,
                .refreshPowerState,
                .handleChargeHysteresis,
                .handleLimitedPower,
                .restoreSleep
            ]
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.wakeFromSleepEffects(
                percentHandlerRegistered: false
            ),
            [
                .disableSleep,
                .refreshPowerState,
                .handleLimitedPower,
                .restoreSleep
            ]
        )
    }
}
