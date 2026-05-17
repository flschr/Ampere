//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal enum BTAppPrompts {
    private(set) static var open: UInt8 = 0

    static func promptQuit() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.quitMessage
        alert.informativeText = BTLocalization.Prompts.quitInfo
        alert.alertStyle = NSAlert.Style.informational
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            await self.tryQuit()

        case NSApplication.ModalResponse.alertSecondButtonReturn:
            break

        default:
            assertionFailure()
        }
    }

    static func promptApproveDaemon(timeout: UInt8) async throws {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.allowMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.allowInfo
        alert.alertStyle = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.approve)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            try await BTActions.approveDaemon(timeout: timeout)

        case NSApplication.ModalResponse.alertSecondButtonReturn:
            NSApp.terminate(self)

        default:
            assertionFailure()
        }
    }

    static func promptMachineUnsupported() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.unsupportedMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.unsupportedInfo
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = self.runPromptStandalone(alert: alert)
        await self.forceRemoveDaemon()
    }

    static func promptRegisterDaemonError() -> Bool {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.enableFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            return true

        case NSApplication.ModalResponse.alertSecondButtonReturn:
            NSApp.terminate(self)

        default:
            assertionFailure()
        }

        return false
    }

    static func promptRemoveDaemon() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.disableInfo
        alert.alertStyle = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryRemoveDaemon()
        }
    }

    static func promptRemoveDaemonAndAppData(window: NSWindow?) async {
        let alert = NSAlert()
        alert.messageText =
            BTLocalization.Prompts.Daemon.uninstallMessage
        alert.informativeText =
            BTLocalization.Prompts.Daemon.uninstallInfo
        alert.alertStyle = NSAlert.Style.warning
        _ = alert.addButton(
            withTitle: BTLocalization.Prompts.uninstall
        )
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = await self.runPrompt(alert: alert, window: window)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryRemoveDaemonAndAppData(window: window)
        }
    }

    static func promptTryRemoveDaemonError() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryRemoveDaemon()
        }
    }

    static func promptTryQuitError() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryQuit()
        }
    }

    static func promptTryRemoveDaemonAndAppDataError(
        window: NSWindow?
    ) async {
        let alert = NSAlert()
        alert.messageText =
            BTLocalization.Prompts.Daemon.uninstallFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = await self.runPrompt(alert: alert, window: window)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryRemoveDaemonAndAppData(window: window)
        }
    }

    static func promptForceRemoveDaemonError() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.forceRemoveDaemon()
            return
        }

        await self.cleanupAndTerminate()
    }

    static func promptUnexpectedError(window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.unexpectedErrorMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        self.runPrompt(alert: alert, window: window)
    }

    static func promptNotAuthorized(window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.notAuthorizedMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        self.runPrompt(alert: alert, window: window)
    }

    static func promptLicenseRequired(window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.licenseRequiredMessage
        alert.informativeText = BTLocalization.Prompts.licenseRequiredInfo
        alert.alertStyle = NSAlert.Style.informational
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        self.runPrompt(alert: alert, window: window)
    }

    static func promptDaemonCommFailed(window: NSWindow? = nil) {
        Task {
            let alert = NSAlert()
            alert.messageText = BTLocalization.Prompts.Daemon.commFailMessage
            alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
                "\n\n" + BTLocalization.Prompts.Daemon.commFailInfo
            alert.alertStyle = NSAlert.Style.critical
            _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
            _ = await self.runPrompt(alert: alert, window: window)
            NSApp.terminate(self)
        }
    }

    private static func cleanupAndTerminate() async {
        await self.disableStartupAndTerminate(removeAppSettings: true)
    }

    private static func disableStartupAndTerminate(
        removeAppSettings: Bool
    ) async {
        _ = BTLoginItem.disable()

        if removeAppSettings, let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }

        NSApp.terminate(nil)
    }

    private static func tryQuit() async {
        do {
            try await BTActions.quitDaemon()
            await self.disableStartupAndTerminate(removeAppSettings: false)
        } catch {
            await self.promptTryQuitError()
        }
    }

    private static func tryRemoveDaemon() async {
        do {
            try await BTActions.removeDaemon()
            await self.cleanupAndTerminate()
        } catch {
            await self.promptTryRemoveDaemonError()
        }
    }

    private static func tryRemoveDaemonAndAppData(window: NSWindow?) async {
        do {
            try await BTActions.removeDaemon()
            try await self.trashApp()
            await self.cleanupAndTerminate()
        } catch {
            await self.promptTryRemoveDaemonAndAppDataError(window: window)
        }
    }

    private static func forceRemoveDaemon() async {
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

    private static func runPromptStandalone(alert: NSAlert) -> NSApplication
        .ModalResponse
    {
        self.open += 1
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        self.open -= 1

        return response
    }

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil) async -> NSApplication.ModalResponse {
        guard let window else {
            return self.runPromptStandalone(alert: alert)
        }

        return await alert.beginSheetModal(for: window)
    }

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil) {
        Task {
            await self.runPrompt(alert: alert, window: window)
        }
    }
}
