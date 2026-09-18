//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal enum BTAppPrompts {
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
}
