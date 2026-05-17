//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@main
@MainActor
internal final class BTAppDelegate: NSObject, NSApplicationDelegate {
    private var initialized = false
    private var statusItemController: BTStatusItemController?
    private var aboutWindowController: NSWindowController?
    @IBOutlet private var menuBarExtraMenu: NSMenu!

    @IBOutlet private var settingsItem: NSMenuItem!
    @IBOutlet private var disableBackgroundItem: NSMenuItem!
    @IBOutlet private var commandsMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_: Notification) {
        BTUpdateController.shared.start()

        Task {
            let status = await BTActions.startDaemon()
            await self.daemonStatusHandler(status: status)
        }
    }

    func applicationWillTerminate(_: Notification) {
        Task { @BTBackgroundActor in
            BTActions.stop()
        }
    }

    func applicationWillBecomeActive(_: Notification) {
        //
        // Use initialized as an indicator for whether the app has finished
        // daemon setup. The status item can intentionally be hidden.
        //
        guard self.initialized else {
            return
        }

        BTAccessoryMode.deactivate()
    }

    func applicationWillResignActive(_: Notification) {
        guard self.initialized else {
            return
        }

        BTAccessoryMode.activate()
    }

    @IBAction private func removeDaemonHandler(sender _: NSMenuItem) {
        Task {
            await BTAppPrompts.promptRemoveDaemon()
        }
    }

    @IBAction private func showAboutHandler(sender _: NSMenuItem) {
        if self.aboutWindowController == nil {
            let aboutController = BTAboutInfoViewController()
            let window = NSWindow(contentViewController: aboutController)
            window.title = BTLocalization.Settings.About.infoButtonAccessibilityLabel
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            self.aboutWindowController = NSWindowController(window: window)
        }

        self.aboutWindowController?.window?.center()
        self.aboutWindowController?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction private func checkForUpdatesHandler(sender: NSMenuItem) {
        BTUpdateController.shared.checkForUpdates(sender)
    }

    private func daemonStatusHandler(status: BTDaemonManagement.Status) async {
        switch status {
        case .notRegistered:
            os_log("Daemon not registered")

            if BTAppPrompts.promptRegisterDaemonError() {
                let status = await BTActions.startDaemon()
                await self.daemonStatusHandler(status: status)
            }

        case .enabled:
            os_log("Daemon is enabled")

            do {
                try await BTDaemonXPCClient.isSupported()
                if !BTActions.enableLoginItem() {
                    BTErrorHandler.errorHandler(error: BTError.unknown)
                }

                self.disableBackgroundItem.isEnabled = true
                self.settingsItem.isEnabled = true
                self.commandsMenuItem.isHidden = false

                if self.statusItemController == nil {
                    let statusItemController = BTStatusItemController(
                        menu: self.menuBarExtraMenu
                    )
                    statusItemController.start()
                    self.statusItemController = statusItemController
                }

                self.initialized = true

                if !NSApp.isActive {
                    BTAccessoryMode.activate()
                }
            } catch BTError.unsupported {
                await BTAppPrompts.promptMachineUnsupported()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }

        case .requiresApproval:
            os_log("Daemon requires approval")

            do {
                try await BTAppPrompts.promptApproveDaemon(timeout: 20)
                await self.daemonStatusHandler(status: .enabled)
            } catch {
                await self.daemonStatusHandler(status: .requiresApproval)
            }

        case .requiresUpgrade:
            os_log("Daemon requires upgrade")

            let storyboard = NSStoryboard(
                name: "Upgrading",
                bundle: nil
            )
            let upgradingController = storyboard
                .instantiateInitialController() as! NSWindowController
            upgradingController.window?.center()
            upgradingController.showWindow(self)

            let status = await BTActions.upgradeDaemon()
            upgradingController.close()
            await self.daemonStatusHandler(status: status)
        }
    }
}
