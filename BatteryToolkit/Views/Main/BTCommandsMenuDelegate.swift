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

    private func hidePowerItems() {
        self.disablePowerAdapterItem.isHidden = true
        self.enablePowerAdapterItem.isHidden = true
        self.chargeToFullNowItem.isHidden = true
        self.chargeToLimitNowItem.isHidden = true
        self.disableChargingItem.isHidden = true
        self.requestChargingToFullItem.isHidden = true
        self.requestChargingToLimitItem.isHidden = true
        self.cancelChargingRequestItem.isHidden = true
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

            let enabledNum = state[BTStateInfo.Keys.enabled] as? NSNumber
            guard let enabled = enabledNum?.boolValue else {
                throw BTError.commFailed
            }

            guard enabled else {
                self.remainingTimeItem?.isHidden = true
                self.infoUnknownStateItem.isHidden = true
                self.infoPowerAdapterEnabledItem.isHidden = true
                self.infoPowerAdapterDisabledItem.isHidden = true
                self.infoChargingToLimitItem.isHidden = true
                self.infoChargingToFullItem.isHidden = true
                self.infoChargingUnknownModeItem.isHidden = true
                self.infoNotChargingItem.isHidden = true
                self.infoRequestedChargingToLimitItem.isHidden = true
                self.infoRequestedChargingToFullItem.isHidden = true
                self.infoNotChargingUnknownModeItem.isHidden = true

                self.hidePowerItems()

                self.pauseActivityItem.isHidden = true
                self.resumeActivityItem.isHidden = false

                self.infoPausedItem.isHidden = false

                return
            }

            self.infoPausedItem.isHidden = true

            self.resumeActivityItem.isHidden = true
            self.pauseActivityItem.isHidden = false

            let powerDisabledNum =
            state[BTStateInfo.Keys.powerDisabled] as? NSNumber
            let connectedNum =
            state[BTStateInfo.Keys.connected] as? NSNumber
            let chargingDisabledNum =
            state[BTStateInfo.Keys.chargingDisabled] as? NSNumber
            let batteryPercentNum =
            state[BTStateInfo.Keys.batteryPercent] as? NSNumber
            let progressNum = state[BTStateInfo.Keys.progress] as? NSNumber
            let chargingModeNum =
            state[BTStateInfo.Keys.chargingMode] as? NSNumber
            let maxChargeNum =
            state[BTStateInfo.Keys.maxCharge] as? NSNumber
            let minChargeNum =
            settings[BTSettingsInfo.Keys.minCharge] as? NSNumber

            guard
                let powerDisabled = powerDisabledNum?.boolValue,
                let connected = connectedNum?.boolValue,
                let chargingDisabled = chargingDisabledNum?.boolValue,
                let batteryPercent = batteryPercentNum?.intValue,
                let progress = progressNum?.intValue,
                let chargingMode = chargingModeNum?.intValue,
                let maxCharge = maxChargeNum?.intValue,
                let minCharge = minChargeNum?.intValue
            else {
                throw BTError.commFailed
            }

            self.updateRemainingTimeItem(
                powerDisabled: powerDisabled,
                connected: connected,
                chargingDisabled: chargingDisabled,
                batteryPercent: batteryPercent,
                chargingMode: chargingMode,
                maxCharge: maxCharge,
                minCharge: minCharge
            )
            
            self.infoUnknownStateItem.isHidden = true
            
            if !powerDisabled {
                self.infoPowerAdapterDisabledItem.isHidden = true
                self.infoPowerAdapterEnabledItem.isHidden = false
                self.infoPowerAdapterEnabledItem.title =
                    BTLocalization.Commands.usingPowerAdapter
                
                self.enablePowerAdapterItem.isHidden = true
                self.disablePowerAdapterItem.isHidden = false
                self.disablePowerAdapterItem.title =
                    BTLocalization.Commands.usePowerAdapter
                self.disablePowerAdapterItem.state = .on
            } else {
                self.infoPowerAdapterEnabledItem.isHidden = true
                self.infoPowerAdapterDisabledItem.isHidden = false
                self.infoPowerAdapterDisabledItem.title =
                    BTLocalization.Commands.runningOnBattery
                
                self.disablePowerAdapterItem.isHidden = true
                self.enablePowerAdapterItem.isHidden = false
                self.enablePowerAdapterItem.title =
                    BTLocalization.Commands.usePowerAdapter
                self.enablePowerAdapterItem.state = .off
            }
            
            if !chargingDisabled {
                self.infoNotChargingItem.isHidden = true
                self.infoRequestedChargingToLimitItem.isHidden = true
                self.infoRequestedChargingToFullItem.isHidden = true
                self.infoNotChargingUnknownModeItem.isHidden = true
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue),
                    Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true
                    self.infoChargingToLimitItem.isHidden = false
                    self.infoChargingToLimitItem.title =
                        BTLocalization.Commands.chargingUntil(
                            maxCharge: maxCharge
                        )
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.infoChargingToLimitItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = false
                    self.infoChargingToFullItem.title =
                        BTLocalization.Commands.chargingToFull
                    
                default:
                    os_log("Unknown charging mode: \(chargingMode)")
                    self.infoChargingToLimitItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = false
                }
            } else {
                self.infoChargingToLimitItem.isHidden = true
                self.infoChargingToFullItem.isHidden = true
                self.infoChargingUnknownModeItem.isHidden = true
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue):
                    self.infoRequestedChargingToLimitItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoNotChargingItem.isHidden = false
                    self.infoNotChargingItem.title =
                        BTLocalization.Commands.holdingCharge(
                            minCharge: minCharge
                        )
                    
                case Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoRequestedChargingToLimitItem.isHidden = false
                    self.infoRequestedChargingToLimitItem.title =
                        BTLocalization.Commands.waitingToCharge(
                            maxCharge: maxCharge
                        )
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToLimitItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = false
                    self.infoRequestedChargingToFullItem.title =
                        BTLocalization.Commands.waitingToChargeFull
                    
                default:
                    os_log("Unknown charging mode: \(chargingMode)")
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToLimitItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = false
                }
            }
            
            let chargeBelowMax = progress <= BTStateInfo.ChargingProgress
                .belowMax.rawValue
            let chargeBelowFull = progress <= BTStateInfo.ChargingProgress
                .belowFull.rawValue

            self.chargeToLimitNowItem.title =
                BTLocalization.Commands.chargeToLimitNow(maxCharge: maxCharge)
            self.requestChargingToLimitItem.title =
                BTLocalization.Commands.requestChargingToLimitNow(
                    maxCharge: maxCharge
                )

            if connected {
                self.requestChargingToFullItem.isHidden = true
                self.requestChargingToLimitItem.isHidden = true
                self.cancelChargingRequestItem.isHidden = true
                self.disableChargingItem.isHidden = chargingDisabled
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue),
                    Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.chargeToLimitNowItem
                        .isHidden = !chargingDisabled || !chargeBelowMax
                    self.chargeToFullNowItem.isHidden = !chargeBelowFull
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.chargeToFullNowItem.isHidden = true
                    self.chargeToLimitNowItem.isHidden = !chargeBelowMax
                    
                default:
                    self.chargeToFullNowItem.isHidden = !chargeBelowFull
                    self.chargeToLimitNowItem.isHidden = !chargeBelowMax
                }
            } else {
                self.chargeToFullNowItem.isHidden = true
                self.chargeToLimitNowItem.isHidden = true
                self.disableChargingItem.isHidden = true
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue):
                    self.cancelChargingRequestItem.isHidden = true
                    self.requestChargingToFullItem
                        .isHidden = !chargeBelowFull
                    self.requestChargingToLimitItem
                        .isHidden = !chargeBelowMax
                    
                case Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.requestChargingToLimitItem.isHidden = true
                    self.requestChargingToFullItem
                        .isHidden = !chargeBelowFull
                    self.cancelChargingRequestItem.isHidden = false
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.requestChargingToFullItem.isHidden = true
                    self.requestChargingToLimitItem
                        .isHidden = !chargeBelowMax
                    self.cancelChargingRequestItem.isHidden = false
                    
                default:
                    self.requestChargingToFullItem
                        .isHidden = !chargeBelowFull
                    self.requestChargingToLimitItem
                        .isHidden = !chargeBelowMax
                    self.cancelChargingRequestItem.isHidden = false
                }
            }
        } catch {
            self.remainingTimeItem?.isHidden = true
            self.infoPowerAdapterEnabledItem.isHidden = true
            self.infoPowerAdapterDisabledItem.isHidden = true
            self.infoChargingToLimitItem.isHidden = true
            self.infoChargingToFullItem.isHidden = true
            self.infoChargingUnknownModeItem.isHidden = true
            self.infoNotChargingItem.isHidden = true
            self.infoRequestedChargingToLimitItem.isHidden = true
            self.infoRequestedChargingToFullItem.isHidden = true
            self.infoNotChargingUnknownModeItem.isHidden = true

            self.hidePowerItems()

            self.infoUnknownStateItem.isHidden = false

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

    private func updateRemainingTimeItem(
        powerDisabled: Bool,
        connected: Bool,
        chargingDisabled: Bool,
        batteryPercent: Int,
        chargingMode: Int,
        maxCharge: Int,
        minCharge: Int
    ) {
        guard
            let title = self.remainingTimeTitle(
                powerDisabled: powerDisabled,
                connected: connected,
                chargingDisabled: chargingDisabled,
                batteryPercent: batteryPercent,
                chargingMode: chargingMode,
                maxCharge: maxCharge,
                minCharge: minCharge
            )
        else {
            self.remainingTimeItem?.isHidden = true
            return
        }

        self.remainingTimeItem?.title = title
        self.remainingTimeItem?.isHidden = false
    }

    private func remainingTimeTitle(
        powerDisabled: Bool,
        connected: Bool,
        chargingDisabled: Bool,
        batteryPercent: Int,
        chargingMode: Int,
        maxCharge: Int,
        minCharge: Int
    ) -> String? {
        if !connected || powerDisabled {
            guard let estimate = IOPSPrivate.GetTimeToEmptyEstimate() else {
                return nil
            }

            if chargingDisabled &&
                chargingMode == Int(BTStateInfo.ChargingMode.standard.rawValue) &&
                batteryPercent > minCharge {
                return self.timeTitle(
                    targetPercent: minCharge,
                    seconds: self.scaledDischargeTime(
                        estimate: estimate,
                        currentPercent: batteryPercent,
                        targetPercent: minCharge
                    )
                )
            }

            return self.timeTitleToEmpty(seconds: estimate)
        }

        guard !chargingDisabled else {
            return nil
        }

        guard let estimate = IOPSPrivate.GetTimeToFullChargeEstimate() else {
            return nil
        }

        switch chargingMode {
        case Int(BTStateInfo.ChargingMode.toFull.rawValue):
            return self.timeTitle(
                targetPercent: 100,
                seconds: self.scaledChargeTime(
                    estimate: estimate,
                    currentPercent: batteryPercent,
                    targetPercent: 100
                )
            )

        default:
            return self.timeTitle(
                targetPercent: maxCharge,
                seconds: self.scaledChargeTime(
                    estimate: estimate,
                    currentPercent: batteryPercent,
                    targetPercent: maxCharge
                )
            )
        }
    }

    private func scaledDischargeTime(
        estimate: TimeInterval,
        currentPercent: Int,
        targetPercent: Int
    ) -> TimeInterval? {
        guard currentPercent > 0 && targetPercent < currentPercent else {
            return nil
        }

        return estimate *
            (Double(currentPercent - targetPercent) / Double(currentPercent))
    }

    private func scaledChargeTime(
        estimate: TimeInterval,
        currentPercent: Int,
        targetPercent: Int
    ) -> TimeInterval? {
        guard currentPercent < 100 && targetPercent > currentPercent else {
            return nil
        }

        return estimate *
            (Double(targetPercent - currentPercent) / Double(100 - currentPercent))
    }

    private func timeTitleToEmpty(seconds: TimeInterval?) -> String? {
        guard let duration = self.durationString(seconds: seconds) else {
            return nil
        }

        return BTLocalization.Commands.untilEmpty(duration: duration)
    }

    private func timeTitle(
        targetPercent: Int,
        seconds: TimeInterval?
    ) -> String? {
        guard let duration = self.durationString(seconds: seconds) else {
            return nil
        }

        return BTLocalization.Commands.untilCharge(
            percent: targetPercent,
            duration: duration
        )
    }

    private func durationString(seconds: TimeInterval?) -> String? {
        guard let seconds, seconds.isFinite, seconds > 0 else {
            return nil
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2

        return formatter.string(from: seconds)
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
