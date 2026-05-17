//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal struct BTMenuItemSnapshot: Equatable, Sendable {
    var isHidden: Bool
    var title: String?
    var stateOn: Bool?

    static let hidden = Self(isHidden: true, title: nil, stateOn: nil)
    static let visible = Self(isHidden: false, title: nil, stateOn: nil)

    static func visible(title: String, stateOn: Bool? = nil) -> Self {
        Self(isHidden: false, title: title, stateOn: stateOn)
    }
}

internal struct BTCommandsMenuSnapshot: Equatable, Sendable {
    var statusHeader = BTMenuItemSnapshot.hidden
    var remainingTime = BTMenuItemSnapshot.hidden
    var unknownState = BTMenuItemSnapshot.hidden
    var paused = BTMenuItemSnapshot.hidden
    var powerAdapterEnabled = BTMenuItemSnapshot.hidden
    var powerAdapterDisabled = BTMenuItemSnapshot.hidden
    var chargingToLimit = BTMenuItemSnapshot.hidden
    var chargingToFull = BTMenuItemSnapshot.hidden
    var chargingUnknownMode = BTMenuItemSnapshot.hidden
    var notCharging = BTMenuItemSnapshot.hidden
    var requestedChargingToLimit = BTMenuItemSnapshot.hidden
    var requestedChargingToFull = BTMenuItemSnapshot.hidden
    var notChargingUnknownMode = BTMenuItemSnapshot.hidden
    var disablePowerAdapter = BTMenuItemSnapshot.hidden
    var enablePowerAdapter = BTMenuItemSnapshot.hidden
    var chargeToFullNow = BTMenuItemSnapshot.hidden
    var chargeToLimitNow = BTMenuItemSnapshot.hidden
    var disableCharging = BTMenuItemSnapshot.hidden
    var requestChargingToFull = BTMenuItemSnapshot.hidden
    var requestChargingToLimit = BTMenuItemSnapshot.hidden
    var cancelChargingRequest = BTMenuItemSnapshot.hidden
    var pauseActivity = BTMenuItemSnapshot.hidden
    var resumeActivity = BTMenuItemSnapshot.hidden

    static var unknown: Self {
        var snapshot = Self()
        snapshot.statusHeader = .visible(
            title: BTLocalization.Commands.unknownState
        )
        snapshot.unknownState = .visible(
            title: BTLocalization.Commands.unknownState
        )
        return snapshot
    }
}

internal enum BTCommandsMenuSnapshotFactory {
    static func make(
        state: BTBatteryState,
        settings: BTBatterySettings,
        timeToEmptyEstimate: TimeInterval?,
        timeToFullEstimate: TimeInterval?
    ) -> BTCommandsMenuSnapshot {
        guard state.enabled else {
            var snapshot = BTCommandsMenuSnapshot()
            snapshot.statusHeader = .visible(title: BTLocalization.Commands.paused)
            snapshot.paused = .visible(title: BTLocalization.Commands.paused)
            snapshot.resumeActivity = .visible
            return snapshot
        }

        var snapshot = BTCommandsMenuSnapshot()
        snapshot.pauseActivity = .visible
        snapshot.remainingTime = self.remainingTimeItem(
            state: state,
            settings: settings,
            timeToEmptyEstimate: timeToEmptyEstimate,
            timeToFullEstimate: timeToFullEstimate
        )
        snapshot.chargeToLimitNow = .visible(
            title: BTLocalization.Commands.chargeToLimitNow(
                maxCharge: state.maxCharge
            )
        )
        snapshot.requestChargingToLimit = .visible(
            title: BTLocalization.Commands.requestChargingToLimitNow(
                maxCharge: state.maxCharge
            )
        )

        self.applyPowerAdapterItems(state: state, snapshot: &snapshot)
        self.applyChargingStatusItems(
            state: state,
            settings: settings,
            snapshot: &snapshot
        )
        self.applyPowerCommandItems(state: state, snapshot: &snapshot)
        snapshot.statusHeader = self.statusHeaderItem(from: snapshot)

        return snapshot
    }

    private static func statusHeaderItem(
        from snapshot: BTCommandsMenuSnapshot
    ) -> BTMenuItemSnapshot {
        if let title = self.visibleTitle(snapshot.chargingToLimit)
            ?? self.visibleTitle(snapshot.chargingToFull)
            ?? self.visibleTitle(snapshot.chargingUnknownMode)
            ?? self.visibleTitle(snapshot.notCharging)
            ?? self.visibleTitle(snapshot.requestedChargingToLimit)
            ?? self.visibleTitle(snapshot.requestedChargingToFull)
            ?? self.visibleTitle(snapshot.notChargingUnknownMode) {
            return .visible(title: title)
        }

        if let title = self.visibleTitle(snapshot.powerAdapterEnabled)
            ?? self.visibleTitle(snapshot.powerAdapterDisabled)
            ?? self.visibleTitle(snapshot.remainingTime) {
            return .visible(title: title)
        }

        return .hidden
    }

    private static func visibleTitle(_ snapshot: BTMenuItemSnapshot) -> String? {
        guard !snapshot.isHidden else {
            return nil
        }

        return snapshot.title
    }

    private static func applyPowerAdapterItems(
        state: BTBatteryState,
        snapshot: inout BTCommandsMenuSnapshot
    ) {
        if state.powerDisabled {
            snapshot.powerAdapterDisabled = .visible(
                title: BTLocalization.Commands.runningOnBattery
            )
            snapshot.enablePowerAdapter = .visible(
                title: BTLocalization.Commands.usePowerAdapter,
                stateOn: false
            )
        } else if !state.connected {
            snapshot.powerAdapterDisabled = .visible(
                title: BTLocalization.Commands.runningOnBattery
            )
            snapshot.disablePowerAdapter = .visible(
                title: BTLocalization.Commands.usePowerAdapter,
                stateOn: true
            )
        } else {
            snapshot.powerAdapterEnabled = .visible(
                title: BTLocalization.Commands.usingPowerAdapter
            )
            snapshot.disablePowerAdapter = .visible(
                title: BTLocalization.Commands.usePowerAdapter,
                stateOn: true
            )
        }
    }

    private static func applyChargingStatusItems(
        state: BTBatteryState,
        settings: BTBatterySettings,
        snapshot: inout BTCommandsMenuSnapshot
    ) {
        guard state.connected, !state.powerDisabled else {
            if state.chargingDisabled {
                switch state.chargingMode {
                case .standard:
                    snapshot.notCharging = .visible(
                        title: BTLocalization.Commands.holdingCharge(
                            minCharge: settings.minCharge
                        )
                    )
                case .toLimit:
                    snapshot.requestedChargingToLimit = .visible(
                        title: BTLocalization.Commands.waitingToCharge(
                            maxCharge: state.maxCharge
                        )
                    )
                case .toFull:
                    snapshot.requestedChargingToFull = .visible(
                        title: BTLocalization.Commands.waitingToChargeFull
                    )
                }
            }
            return
        }

        if state.chargingDisabled {
            switch state.chargingMode {
            case .standard:
                snapshot.notCharging = .visible(
                    title: BTLocalization.Commands.holdingCharge(
                        minCharge: settings.minCharge
                    )
                )
            case .toLimit:
                snapshot.requestedChargingToLimit = .visible(
                    title: BTLocalization.Commands.waitingToCharge(
                        maxCharge: state.maxCharge
                    )
                )
            case .toFull:
                snapshot.requestedChargingToFull = .visible(
                    title: BTLocalization.Commands.waitingToChargeFull
                )
            }
        } else {
            switch state.chargingMode {
            case .standard, .toLimit:
                snapshot.chargingToLimit = .visible(
                    title: BTLocalization.Commands.chargingUntil(
                        maxCharge: state.maxCharge
                    )
                )
            case .toFull:
                snapshot.chargingToFull = .visible(
                    title: BTLocalization.Commands.chargingToFull
                )
            }
        }
    }

    private static func applyPowerCommandItems(
        state: BTBatteryState,
        snapshot: inout BTCommandsMenuSnapshot
    ) {
        let chargeBelowMax = state.progress.rawValue <=
            BTStateInfo.ChargingProgress.belowMax.rawValue
        let chargeBelowFull = state.progress.rawValue <=
            BTStateInfo.ChargingProgress.belowFull.rawValue

        if state.connected {
            snapshot.requestChargingToFull.isHidden = true
            snapshot.requestChargingToLimit.isHidden = true
            snapshot.disableCharging.isHidden = state.chargingDisabled

            switch state.chargingMode {
            case .standard, .toLimit:
                snapshot.chargeToLimitNow.isHidden =
                    !state.chargingDisabled || !chargeBelowMax
                snapshot.chargeToFullNow.isHidden = !chargeBelowFull
            case .toFull:
                snapshot.chargeToFullNow.isHidden = true
                snapshot.chargeToLimitNow.isHidden = !chargeBelowMax
            }
        } else {
            snapshot.chargeToFullNow.isHidden = true
            snapshot.chargeToLimitNow.isHidden = true
            snapshot.disableCharging.isHidden = true

            switch state.chargingMode {
            case .standard:
                snapshot.requestChargingToFull.isHidden = !chargeBelowFull
                snapshot.requestChargingToLimit.isHidden = !chargeBelowMax
            case .toLimit:
                snapshot.requestChargingToFull.isHidden = !chargeBelowFull
                snapshot.cancelChargingRequest = .visible
            case .toFull:
                snapshot.requestChargingToLimit.isHidden = !chargeBelowMax
                snapshot.cancelChargingRequest = .visible
            }
        }
    }

    private static func remainingTimeItem(
        state: BTBatteryState,
        settings: BTBatterySettings,
        timeToEmptyEstimate: TimeInterval?,
        timeToFullEstimate: TimeInterval?
    ) -> BTMenuItemSnapshot {
        guard let title = self.remainingTimeTitle(
            state: state,
            settings: settings,
            timeToEmptyEstimate: timeToEmptyEstimate,
            timeToFullEstimate: timeToFullEstimate
        ) else {
            return .hidden
        }

        return .visible(title: title)
    }

    private static func remainingTimeTitle(
        state: BTBatteryState,
        settings: BTBatterySettings,
        timeToEmptyEstimate: TimeInterval?,
        timeToFullEstimate: TimeInterval?
    ) -> String? {
        if !state.connected || state.powerDisabled {
            guard let estimate = timeToEmptyEstimate else {
                return nil
            }

            if state.chargingDisabled &&
                state.chargingMode == .standard &&
                state.batteryPercent > settings.minCharge {
                return self.timeTitle(
                    targetPercent: settings.minCharge,
                    seconds: self.scaledDischargeTime(
                        estimate: estimate,
                        currentPercent: state.batteryPercent,
                        targetPercent: settings.minCharge
                    )
                )
            }

            return self.timeTitleToEmpty(seconds: estimate)
        }

        guard !state.chargingDisabled, let estimate = timeToFullEstimate else {
            return nil
        }

        switch state.chargingMode {
        case .toFull:
            return self.timeTitle(
                targetPercent: 100,
                seconds: self.scaledChargeTime(
                    estimate: estimate,
                    currentPercent: state.batteryPercent,
                    targetPercent: 100
                )
            )
        case .standard, .toLimit:
            return self.timeTitle(
                targetPercent: state.maxCharge,
                seconds: self.scaledChargeTime(
                    estimate: estimate,
                    currentPercent: state.batteryPercent,
                    targetPercent: state.maxCharge
                )
            )
        }
    }

    private static func scaledDischargeTime(
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

    private static func scaledChargeTime(
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

    private static func timeTitleToEmpty(seconds: TimeInterval?) -> String? {
        guard let duration = self.durationString(seconds: seconds) else {
            return nil
        }

        return BTLocalization.Commands.untilEmpty(duration: duration)
    }

    private static func timeTitle(
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

    private static func durationString(seconds: TimeInterval?) -> String? {
        guard let seconds, seconds.isFinite, seconds > 0 else {
            return nil
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2

        return formatter.string(from: seconds)
    }
}
