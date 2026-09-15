//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTLowPowerModeTests: XCTestCase {
    func testLowPowerModeWinsOverStalePowerModeValues() throws {
        let state = try BTLowPowerMode.state(
            customOutput: """
            Battery Power:
             powermode            1
             lowpowermode         0
            AC Power:
             powermode            1
             lowpowermode         0
            """,
            activeOutput: nil
        )

        XCTAssertEqual(state.key, .lowPowerMode)
        XCTAssertFalse(state.isEnabled)
        XCTAssertTrue(state.matches(enabled: false))
    }

    func testLowPowerModeEnabledWhenAllProfilesAreEnabled() throws {
        let state = try BTLowPowerMode.state(
            customOutput: """
            Battery Power:
             lowpowermode         1
            AC Power:
             lowpowermode         1
            """,
            activeOutput: nil
        )

        XCTAssertEqual(state.key, .lowPowerMode)
        XCTAssertTrue(state.isEnabled)
        XCTAssertTrue(state.hasEnabledProfile)
        XCTAssertFalse(state.matches(enabled: true))
    }

    func testBatteryOnlyLowPowerModeMatchesEnabled() throws {
        let state = try BTLowPowerMode.state(
            customOutput: """
            Battery Power:
             lowpowermode         1
            AC Power:
             lowpowermode         0
            """,
            activeOutput: nil
        )

        XCTAssertTrue(state.isEnabled)
        XCTAssertTrue(state.hasEnabledProfile)
        XCTAssertTrue(state.matches(enabled: true))
        XCTAssertFalse(state.matches(enabled: false))
    }

    func testPowerModeIsFallbackWhenLowPowerModeIsMissing() throws {
        let state = try BTLowPowerMode.state(
            customOutput: """
            Battery Power:
             powermode            1
            AC Power:
             powermode            1
            """,
            activeOutput: nil
        )

        XCTAssertEqual(state.key, .powerMode)
        XCTAssertTrue(state.isEnabled)
        XCTAssertFalse(state.matches(enabled: true))
    }

    func testActiveSettingsFallbackUsesLowPowerModeFirst() throws {
        let state = try BTLowPowerMode.state(
            customOutput: """
            Battery Power:
             sleep                1
            AC Power:
             sleep                1
            """,
            activeOutput: """
            Currently in use:
             powermode            1
             lowpowermode         0
            """
        )

        XCTAssertEqual(state.key, .lowPowerMode)
        XCTAssertFalse(state.isEnabled)
    }

    func testCapabilitiesParseSupportedPowerModeKeys() {
        let capabilities = BTLowPowerMode.powerModeCapabilities(
            from: """
            Capabilities for Battery Power:
             displaysleep
             lowpowermode
             powermode
            """
        )

        XCTAssertTrue(capabilities.contains(.lowPowerMode))
        XCTAssertTrue(capabilities.contains(.powerMode))
    }
}
