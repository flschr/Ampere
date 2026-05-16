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

    func testDisconnectedRecoveryEnablesBelowMinOnlyForStandardHold() {
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 49,
                minCharge: 50,
                chargingDisabled: true,
                chargingMode: .standard
            ),
            .enableCharging
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 50,
                minCharge: 50,
                chargingDisabled: true,
                chargingMode: .standard
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 49,
                minCharge: 50,
                chargingDisabled: false,
                chargingMode: .standard
            ),
            .none
        )
        XCTAssertEqual(
            BTPowerEventStateMachine.disconnectedRecoveryEffect(
                percent: 49,
                minCharge: 50,
                chargingDisabled: true,
                chargingMode: .toFull
            ),
            .none
        )
    }

    func testDisconnectedBatteryMonitoringOnlyForStandardHold() {
        XCTAssertTrue(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingDisabled: true,
                chargingMode: .standard
            )
        )
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingDisabled: false,
                chargingMode: .standard
            )
        )
        XCTAssertFalse(
            BTPowerEventStateMachine.shouldMonitorDisconnectedBattery(
                chargingDisabled: true,
                chargingMode: .toLimit
            )
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
