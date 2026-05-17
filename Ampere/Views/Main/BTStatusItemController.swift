//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit
import os.log

extension Notification.Name {
    static let btStatusItemNeedsRefresh =
        Notification.Name("app.justasimple.ampere.statusItemNeedsRefresh")
}

@MainActor
internal final class BTStatusItemController {
    private static let statusItemAutosaveName =
        NSStatusItem.AutosaveName("app.justasimple.ampere.statusItem")

    private let menu: NSMenu
    private var statusItem: NSStatusItem?
    private var refreshTimer: DispatchSourceTimer?
    private var refreshObserver: NSObjectProtocol?

    init(menu: NSMenu) {
        self.menu = menu
    }

    func start() {
        self.rebuildStatusItem()
        self.startRefreshTimer()
        self.startRefreshObserver()
    }

    func stop() {
        self.refreshTimer?.cancel()
        self.refreshTimer = nil
        if let refreshObserver {
            NotificationCenter.default.removeObserver(refreshObserver)
            self.refreshObserver = nil
        }
        self.removeStatusItem()
    }

    private func startRefreshTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.refresh()
            }
        }
        timer.schedule(deadline: .now(), repeating: 30)
        timer.resume()
        self.refreshTimer = timer
    }

    private func rebuildStatusItem() {
        self.removeStatusItem()

        let statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        statusItem.autosaveName = Self.statusItemAutosaveName
        statusItem.isVisible = true
        statusItem.menu = self.menu
        self.statusItem = statusItem

        Task {
            await self.refresh()
        }
    }

    private func removeStatusItem() {
        guard let statusItem else {
            return
        }

        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    private func startRefreshObserver() {
        self.refreshObserver = NotificationCenter.default.addObserver(
            forName: .btStatusItemNeedsRefresh,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    private func refresh() async {
        guard let button = self.statusItem?.button else {
            return
        }

        let snapshot = await self.statusSnapshot()
        button.image = snapshot.image
        button.title = snapshot.title
        button.imagePosition = .imageLeading
        button.imageScaling = .scaleNone
        button.contentTintColor = snapshot.contentTintColor
        button.toolTip = snapshot.toolTip
    }

    private func statusSnapshot() async -> BTStatusItemSnapshot {
        do {
            let state = try await BTActions.getState()
            let settings = try await BTActions.getSettings()
            let lowPowerModeEnabled =
                (try? await BTActions.getLowPowerModeEnabled()) ?? false
            return BTStatusItemSnapshotFactory.make(
                state: state,
                settings: settings,
                lowPowerModeEnabled: lowPowerModeEnabled
            )
        } catch {
            os_log("Failed to refresh status item: \(error, privacy: .public)")
            return BTStatusItemSnapshotFactory.unknown()
        }
    }
}
