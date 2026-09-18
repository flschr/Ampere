//
// Copyright (C) 2026 René Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import XCTest

final class BTAppExitCoordinatorTests: XCTestCase {
    @MainActor
    func testQuitStopsDaemonWithoutDisablingLoginItem() async throws {
        var events: [String] = []
        let coordinator = BTAppExitCoordinator(
            quitDaemon: { events.append("stop daemon") },
            disableLoginItem: {
                events.append("disable login item")
                return true
            },
            clearAppSettings: { events.append("clear settings") },
            terminate: { events.append("terminate") }
        )

        try await coordinator.quit()

        XCTAssertEqual(events, ["stop daemon", "terminate"])
    }

    @MainActor
    func testFailedQuitDoesNotChangeStartupOrTerminate() async {
        struct StopError: Error {}
        var events: [String] = []
        let coordinator = BTAppExitCoordinator(
            quitDaemon: { throw StopError() },
            disableLoginItem: {
                events.append("disable login item")
                return true
            },
            clearAppSettings: { events.append("clear settings") },
            terminate: { events.append("terminate") }
        )

        do {
            try await coordinator.quit()
            XCTFail("Expected the daemon stop to fail")
        } catch is StopError {
            XCTAssertTrue(events.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    @MainActor
    func testRemovalDisablesLoginItemAndClearsSettings() {
        var events: [String] = []
        let coordinator = BTAppExitCoordinator(
            quitDaemon: { events.append("stop daemon") },
            disableLoginItem: {
                events.append("disable login item")
                return true
            },
            clearAppSettings: { events.append("clear settings") },
            terminate: { events.append("terminate") }
        )

        coordinator.finishRemoval()

        XCTAssertEqual(
            events,
            ["disable login item", "clear settings", "terminate"]
        )
    }
}
