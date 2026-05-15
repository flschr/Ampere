//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit
import os.log

@MainActor
internal final class BTStatusItemController {
    private let menu: NSMenu
    private var statusItem: NSStatusItem?
    private var refreshTimer: DispatchSourceTimer?
    private var displayModeObserver: NSObjectProtocol?

    init(menu: NSMenu) {
        self.menu = menu
    }

    func start() {
        self.displayModeObserver = NotificationCenter.default.addObserver(
            forName: BTStatusItemDisplayMode.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildStatusItem()
            }
        }

        self.rebuildStatusItem()
        self.startRefreshTimer()
    }

    func stop() {
        self.refreshTimer?.cancel()
        self.refreshTimer = nil
        self.displayModeObserver.map(NotificationCenter.default.removeObserver)
        self.displayModeObserver = nil
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

        guard BTStatusItemDisplayMode.current != .hidden else {
            return
        }

        let statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
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

    private func refresh() async {
        guard let button = self.statusItem?.button else {
            return
        }

        let snapshot = await self.statusSnapshot()
        let mode = BTStatusItemDisplayMode.current

        switch mode {
        case .iconOnly:
            button.image = snapshot.image
            button.title = ""

        case .percentInIcon:
            button.image = BTStatusItemIconFactory.percentImage(
                percent: snapshot.percent,
                fallback: snapshot.image
            )
            button.title = ""

        case .percentOnly:
            button.image = nil
            button.title = snapshot.title

        case .hidden:
            button.image = nil
            button.title = ""
        }

        button.toolTip = snapshot.toolTip
    }

    private func statusSnapshot() async -> BTStatusItemSnapshot {
        let percent = IOPSPrivate.GetPercentRemaining()?.0

        do {
            let state = try await BTActions.getState()
            let settings = try await BTActions.getSettings()
            return BTStatusItemSnapshotFactory.make(
                state: state,
                settings: settings,
                percent: percent
            )
        } catch {
            os_log("Failed to refresh status item: \(error, privacy: .public)")
            return BTStatusItemSnapshotFactory.unknown(percent: percent)
        }
    }
}
