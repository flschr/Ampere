//
// Copyright (C) 2026 René Fischer / Just a Simple App. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTAboutInfoModelTests: XCTestCase {
    func testVersionTextUsesMarketingVersionOnly() {
        let info = BTAboutInfo(infoDictionary: [
            "CFBundleDisplayName": "Ampere",
            "CFBundleShortVersionString": "1.2",
            "CFBundleVersion": "45",
        ])

        XCTAssertTrue(info.versionText.contains("1.2"))
        XCTAssertFalse(info.versionText.contains("45"))
        XCTAssertFalse(info.versionText.contains("Build"))
    }

    func testVersionTextOmitsBuildDecoration() {
        let info = BTAboutInfo(infoDictionary: [
            "CFBundleDisplayName": "Ampere",
            "CFBundleShortVersionString": "1.2",
        ])

        XCTAssertTrue(info.versionText.contains("1.2"))
        XCTAssertFalse(info.versionText.contains("("))
    }
}
