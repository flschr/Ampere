//
// Copyright (C) 2026 René Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

@MainActor
internal struct BTAppExitCoordinator {
    let quitDaemon: () async throws -> Void
    let disableLoginItem: () -> Bool
    let clearAppSettings: () -> Void
    let terminate: () -> Void

    func quit() async throws {
        try await self.quitDaemon()
        self.terminate()
    }

    func finishRemoval() {
        _ = self.disableLoginItem()
        self.clearAppSettings()
        self.terminate()
    }
}
