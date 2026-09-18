//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// Copyright (C) 2026 René Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal extension BTAppPrompts {
    private(set) static var open: UInt8 = 0

    private static var exitCoordinator: BTAppExitCoordinator {
        BTAppExitCoordinator(
            quitDaemon: { try await BTActions.quitDaemon() },
            disableLoginItem: { BTLoginItem.disable() },
            clearAppSettings: {
                if let domain = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                }
            },
            terminate: { NSApp.terminate(nil) }
        )
    }

    static func cleanupAndTerminate() async {
        self.exitCoordinator.finishRemoval()
    }

    static func tryQuit() async {
        do {
            try await self.exitCoordinator.quit()
        } catch {
            await self.promptTryQuitError()
        }
    }

    static func tryRemoveDaemon() async {
        do {
            try await BTActions.removeDaemon()
            await self.cleanupAndTerminate()
        } catch {
            await self.promptTryRemoveDaemonError()
        }
    }

    static func tryRemoveDaemonAndAppData(window: NSWindow?) async {
        do {
            try await BTActions.removeDaemon()
            try await self.trashApp()
            await self.cleanupAndTerminate()
        } catch {
            await self.promptTryRemoveDaemonAndAppDataError(window: window)
        }
    }

    static func forceRemoveDaemon() async {
        do {
            try await BTActions.removeDaemon()
            await self.cleanupAndTerminate()
        } catch {
            await self.promptForceRemoveDaemonError()
        }
    }

    private static func trashApp() async throws {
        let appUrl = Bundle.main.bundleURL

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, any Error>) in
            NSWorkspace.shared.recycle([appUrl]) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume()
            }
        }
    }

    static func runPromptStandalone(alert: NSAlert) -> NSApplication.ModalResponse {
        self.open += 1
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        self.open -= 1

        return response
    }

    static func runPrompt(
        alert: NSAlert,
        window: NSWindow? = nil
    ) async -> NSApplication.ModalResponse {
        guard let window else {
            return self.runPromptStandalone(alert: alert)
        }

        return await alert.beginSheetModal(for: window)
    }

    static func runPrompt(alert: NSAlert, window: NSWindow? = nil) {
        Task {
            await self.runPrompt(alert: alert, window: window)
        }
    }
}
