//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTMagSafeIndicatorStateTests: XCTestCase {
    private let chargingBattery: (percent: UInt8, charging: Bool, fullyCharged: Bool) =
        (80, true, false)
    private let pausedBattery: (percent: UInt8, charging: Bool, fullyCharged: Bool) =
        (80, false, false)

    func testSystemManagedModeAlwaysLeavesIndicatorToMacOS() {
        XCTAssertEqual(
            self.state(mode: .systemManaged, battery: self.pausedBattery),
            .system
        )
    }

    func testDisabledSyncAndMissingBatteryLeaveIndicatorToMacOS() {
        XCTAssertEqual(
            self.state(syncEnabled: false, battery: self.pausedBattery),
            .system
        )
        XCTAssertEqual(self.state(battery: nil), .system)
        XCTAssertEqual(
            self.state(externalPower: false, battery: self.pausedBattery),
            .system
        )
    }

    func testDisabledAdapterTurnsIndicatorOff() {
        XCTAssertEqual(
            self.state(adapterDisabled: true, battery: self.pausedBattery),
            .off
        )
        XCTAssertEqual(
            self.state(adapterDisabled: true, battery: nil),
            .off
        )
    }

    func testChargingIsSteadyAmberEvenAtTarget() {
        XCTAssertEqual(
            self.state(battery: self.chargingBattery),
            .amber
        )
    }

    func testReachedTargetIsGreenAndPauseBelowTargetIsAmber() {
        XCTAssertEqual(self.state(battery: self.pausedBattery), .green)
        XCTAssertEqual(
            self.state(
                battery: (75, false, false)
            ),
            .amber
        )
        XCTAssertEqual(
            self.state(battery: self.pausedBattery, target: 100),
            .amber
        )
    }

    func testStaleFullyChargedFlagDoesNotOverrideTemporaryFullTarget() {
        XCTAssertEqual(
            self.state(
                battery: (80, false, true),
                target: 100
            ),
            .amber
        )
    }

    func testLegacyChargeStopWinsOverLaggingBatterySample() {
        XCTAssertEqual(
            self.state(
                mode: .legacySMC,
                battery: self.chargingBattery,
                directChargingDisabled: true
            ),
            .green
        )
    }

    private func state(
        mode: BTChargeControlMode = .firmwareSMC,
        syncEnabled: Bool = true,
        adapterDisabled: Bool = false,
        externalPower: Bool = true,
        battery: (percent: UInt8, charging: Bool, fullyCharged: Bool)?,
        target: UInt8 = 80,
        directChargingDisabled: Bool = false
    ) -> BTMagSafeIndicatorState {
        BTMagSafeIndicatorState.resolve(
            mode: mode,
            syncEnabled: syncEnabled,
            adapterDisabled: adapterDisabled,
            externalPower: externalPower,
            battery: battery,
            target: target,
            directChargingDisabled: directChargingDisabled
        )
    }
}
