//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTLicenseModelTests: XCTestCase {
    func testSourceBuildLicenseManagerAllowsChargingManagement() {
        let status = BTSourceBuildLicenseManager().currentStatus()

        XCTAssertEqual(status, .sourceBuild)
        XCTAssertTrue(status.canManageCharging)
    }

    func testExpiredLicenseDisablesChargingManagement() {
        XCTAssertFalse(BTLicenseStatus.expired.canManageCharging)
    }

    func testDaemonPaidCommandsRequireChargingManagementLicense() {
        XCTAssertTrue(
            BTDaemonCommCommand.chargeToLimit
                .requiresChargingManagementLicense
        )
        XCTAssertTrue(
            BTDaemonCommCommand.disableCharging
                .requiresChargingManagementLicense
        )
        XCTAssertFalse(
            BTDaemonCommCommand.enablePowerAdapter
                .requiresChargingManagementLicense
        )
        XCTAssertFalse(
            BTDaemonCommCommand.pauseActivity
                .requiresChargingManagementLicense
        )
    }
}
