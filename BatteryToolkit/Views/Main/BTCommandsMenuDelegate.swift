//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTCommandsMenuDelegate: NSObject, NSMenuDelegate {
    private static let remainingTimeItemTag = 23_043

    @IBOutlet private var infoUnknownStateItem: NSMenuItem!
    @IBOutlet private var infoPausedItem: NSMenuItem!

    @IBOutlet private var infoPowerAdapterEnabledItem: NSMenuItem!
    @IBOutlet private var infoPowerAdapterDisabledItem: NSMenuItem!

    @IBOutlet private var infoChargingToLimitItem: NSMenuItem!
    @IBOutlet private var infoChargingToFullItem: NSMenuItem!
    @IBOutlet private var infoChargingUnknownModeItem: NSMenuItem!

    @IBOutlet private var infoNotChargingItem: NSMenuItem!
    @IBOutlet private var infoRequestedChargingToLimitItem: NSMenuItem!
    @IBOutlet private var infoRequestedChargingToFullItem: NSMenuItem!
    @IBOutlet private var infoNotChargingUnknownModeItem: NSMenuItem!

    @IBOutlet private var disablePowerAdapterItem: NSMenuItem!
    @IBOutlet private var enablePowerAdapterItem: NSMenuItem!

    @IBOutlet private var chargeToFullNowItem: NSMenuItem!
    @IBOutlet private var chargeToLimitNowItem: NSMenuItem!
    @IBOutlet private var disableChargingItem: NSMenuItem!

    @IBOutlet private var requestChargingToFullItem: NSMenuItem!
    @IBOutlet private var requestChargingToLimitItem: NSMenuItem!
    @IBOutlet private var cancelChargingRequestItem: NSMenuItem!

    @IBOutlet private var lowPowerModeItem: NSMenuItem!

    @IBOutlet private var pauseActivityItem: NSMenuItem!
    @IBOutlet private var resumeActivityItem: NSMenuItem!

    private var refreshTimer: DispatchSourceTimer? = nil
    private weak var remainingTimeItem: NSMenuItem?

    private func disabledInfoItem(tag: Int) -> NSMenuItem {
        let item = NSMenuItem()
        item.tag = tag
        item.isEnabled = false
        item.isHidden = true
        return item
    }

    private func ensureDynamicInfoItems(in menu: NSMenu) {
        if let item = menu.item(withTag: Self.remainingTimeItemTag) {
            self.remainingTimeItem = item
        } else {
            let item = self.disabledInfoItem(tag: Self.remainingTimeItemTag)
            menu.insertItem(item, at: 0)
            self.remainingTimeItem = item
        }
    }

    private func refreshLowPowerModeItem() async {
        do {
            let enabled = try await BTActions.getLowPowerModeEnabled()
            self.lowPowerModeItem.title = BTLocalization.Commands.lowPowerMode
            self.lowPowerModeItem.state = enabled ? .on : .off
            self.lowPowerModeItem.isEnabled = true
            self.lowPowerModeItem.isHidden = false
        } catch {
            os_log(
                "Failed to refresh Low Power Mode: \(error, privacy: .public)"
            )
            self.lowPowerModeItem.title = BTLocalization.Commands.lowPowerMode
            self.lowPowerModeItem.state = .off
            self.lowPowerModeItem.isEnabled = false
            self.lowPowerModeItem.isHidden = false
        }
    }

    private func refresh() async {
        await self.refreshLowPowerModeItem()

        do {
            let state = try await BTActions.getState()
            let settings = try await BTActions.getSettings()
            let batteryState = try BTBatteryState(payload: state)
            let batterySettings = try BTBatterySettings(payload: settings)
            let snapshot = BTCommandsMenuSnapshotFactory.make(
                state: batteryState,
                settings: batterySettings,
                timeToEmptyEstimate: IOPSPrivate.GetTimeToEmptyEstimate(),
                timeToFullEstimate: IOPSPrivate.GetTimeToFullChargeEstimate()
            )

            self.apply(snapshot: snapshot)
        } catch {
            self.apply(snapshot: .unknown)
            BTErrorHandler.errorHandler(error: error)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        assert(self.refreshTimer == nil)
        self.ensureDynamicInfoItems(in: menu)

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.setEventHandler {
            Task {
                await self.refresh()
            }
        }
        timer.schedule(deadline: .now(), repeating: 5)
        timer.resume()
        self.refreshTimer = timer
    }

    func menuDidClose(_: NSMenu) {
        assert(self.refreshTimer != nil)

        self.refreshTimer!.cancel()
        self.refreshTimer = nil
    }

    private func apply(snapshot: BTCommandsMenuSnapshot) {
        self.apply(snapshot.remainingTime, to: self.remainingTimeItem)
        self.apply(snapshot.unknownState, to: self.infoUnknownStateItem)
        self.apply(snapshot.paused, to: self.infoPausedItem)
        self.apply(
            snapshot.powerAdapterEnabled,
            to: self.infoPowerAdapterEnabledItem
        )
        self.apply(
            snapshot.powerAdapterDisabled,
            to: self.infoPowerAdapterDisabledItem
        )
        self.apply(snapshot.chargingToLimit, to: self.infoChargingToLimitItem)
        self.apply(snapshot.chargingToFull, to: self.infoChargingToFullItem)
        self.apply(
            snapshot.chargingUnknownMode,
            to: self.infoChargingUnknownModeItem
        )
        self.apply(snapshot.notCharging, to: self.infoNotChargingItem)
        self.apply(
            snapshot.requestedChargingToLimit,
            to: self.infoRequestedChargingToLimitItem
        )
        self.apply(
            snapshot.requestedChargingToFull,
            to: self.infoRequestedChargingToFullItem
        )
        self.apply(
            snapshot.notChargingUnknownMode,
            to: self.infoNotChargingUnknownModeItem
        )
        self.apply(snapshot.disablePowerAdapter, to: self.disablePowerAdapterItem)
        self.apply(snapshot.enablePowerAdapter, to: self.enablePowerAdapterItem)
        self.apply(snapshot.chargeToFullNow, to: self.chargeToFullNowItem)
        self.apply(snapshot.chargeToLimitNow, to: self.chargeToLimitNowItem)
        self.apply(snapshot.disableCharging, to: self.disableChargingItem)
        self.apply(
            snapshot.requestChargingToFull,
            to: self.requestChargingToFullItem
        )
        self.apply(
            snapshot.requestChargingToLimit,
            to: self.requestChargingToLimitItem
        )
        self.apply(
            snapshot.cancelChargingRequest,
            to: self.cancelChargingRequestItem
        )
        self.apply(snapshot.pauseActivity, to: self.pauseActivityItem)
        self.apply(snapshot.resumeActivity, to: self.resumeActivityItem)
    }

    private func apply(
        _ snapshot: BTMenuItemSnapshot,
        to item: NSMenuItem?
    ) {
        item?.isHidden = snapshot.isHidden
        if let title = snapshot.title {
            item?.title = title
        }
        if let stateOn = snapshot.stateOn {
            item?.state = stateOn ? .on : .off
        }
    }

    @IBAction private func quitHandler(sender _: NSMenuItem) {
        BTAppPrompts.promptQuit()
    }

    @IBAction private func disablePowerAdapterHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.disablePowerAdapter()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func enablePowerAdapterHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.enablePowerAdapter()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func chargeToLimitHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.chargeToLimit()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func chargeToFullHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.chargeToFull()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func disableChargingHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.disableCharging()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func toggleLowPowerModeHandler(sender _: NSMenuItem) {
        Task {
            do {
                let enabled = try await BTActions.getLowPowerModeEnabled()
                try await BTActions.setLowPowerModeEnabled(!enabled)
                await self.refreshLowPowerModeItem()
                NotificationCenter.default.post(
                    name: .btStatusItemNeedsRefresh,
                    object: nil
                )
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func pauseActivityHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.pauseActivity()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func resumeActivityHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.resumeActiivty()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }
}
