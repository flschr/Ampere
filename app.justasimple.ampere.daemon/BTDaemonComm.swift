//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log
import ServiceManagement

internal final class BTDaemonComm: NSObject, BTDaemonCommProtocol, Sendable {
    func getUniqueId(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        Task { @MainActor in
            reply(BTDaemon.getUniqueId())
        }
    }

    func execute(
        authData: Data?,
        command: UInt8,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        Task { @MainActor in
            guard let command = BTDaemonCommCommand(rawValue: command) else {
                os_log("Unknown command: \(command)")
                reply(BTError.commFailed.rawValue)
                return
            }

            let error = self.execute(authData: authData, command: command)
            reply(error.rawValue)
        }
    }

    @MainActor
    private func execute(authData: Data?, command: BTDaemonCommCommand) -> BTError {
        switch command {
            //
            // Report the supported state to the client, so that it can, e.g.,
            // cleanly uninstall itself if it is unsupported.
            //
            case .isSupported:
                return BTDaemon.supported ? .success : .unsupported
            //
            // The update commands are optional notifications that allow to
            // optimise the process. Usually, the platform power state is reset
            // to its defaults when the daemon exits. These signals may be used
            // to temporarily override this behaviour to preserve the state
            // instead.
            //
            case .prepareUpdate, .finishUpdate:
                return self.executeUpdateCommand(command)

            case .removeLegacyHelperFiles, .prepareDisable:
                return self.executeSystemDaemonCommand(
                    command,
                    authData: authData
                )

            case .enableLowPowerMode, .disableLowPowerMode:
                return self.executeLowPowerModeCommand(
                    command,
                    authData: authData
                )

            default:
                return self.executeSupportedPowerCommand(
                    command,
                    authData: authData
                )
        }
    }

    @MainActor
    private func executeUpdateCommand(_ command: BTDaemonCommCommand) -> BTError {
        switch command {
        case .prepareUpdate:
            os_log("Preparing update")
            BTPowerEvents.updating = true
        case .finishUpdate:
            os_log("Update finished")
            BTPowerEvents.updating = false
        default:
            return .commFailed
        }

        return .success
    }

    @MainActor
    private func executeSystemDaemonCommand(
        _ command: BTDaemonCommCommand,
        authData: Data?
    ) -> BTError {
        guard self.isAuthorized(
            authData: authData,
            rightName: kSMRightModifySystemDaemons
        ) else {
            return .notAuthorized
        }

        switch command {
        case .removeLegacyHelperFiles:
            return BTError(fromBool: BTDaemonManagement.removeLegacyHelperFiles())
        case .prepareDisable:
            return BTError(fromBool: BTDaemonManagement.prepareDisable())
        default:
            return .commFailed
        }
    }

    @MainActor
    private func executeLowPowerModeCommand(
        _ command: BTDaemonCommCommand,
        authData: Data?
    ) -> BTError {
        guard self.hasChargingManagementLicense() else {
            return .licenseRequired
        }

        guard self.isAuthorized(
            authData: authData,
            rightName: BTAuthorizationRights.manage
        ) else {
            return .notAuthorized
        }

        let enabled: Bool
        switch command {
        case .enableLowPowerMode:
            enabled = true
        case .disableLowPowerMode:
            enabled = false
        default:
            return .commFailed
        }

        do {
            try BTLowPowerMode.setEnabled(enabled)
            return .success
        } catch {
            os_log(
                "Failed to update Low Power Mode: \(error, privacy: .public)"
            )
            return .commFailed
        }
    }

    @MainActor
    private func executeSupportedPowerCommand(
        _ command: BTDaemonCommCommand,
        authData: Data?
    ) -> BTError {
        //
        // Power state management functions may only be invoked when supported.
        //
        guard BTDaemon.supported else {
            return .unsupported
        }

        guard !command.requiresChargingManagementLicense ||
            self.hasChargingManagementLicense()
        else {
            return .licenseRequired
        }

        switch command {
        case .enablePowerAdapter:
            return BTError(fromBool: BTPowerEvents.enablePowerAdapter())
        case .chargeToFull:
            return BTError(fromBool: BTPowerEvents.chargeToFull())
        case .chargeToLimit:
            return BTError(fromBool: BTPowerEvents.chargeToLimit())
        case .disablePowerAdapter:
            guard self.isAuthorizedToManage(authData: authData) else {
                return .notAuthorized
            }

            return BTError(fromBool: BTPowerState.disablePowerAdapter())
        case .disableCharging:
            guard self.isAuthorizedToManage(authData: authData) else {
                return .notAuthorized
            }

            return BTError(fromBool: BTPowerEvents.disableCharging())
        case .pauseActivity:
            guard self.isAuthorizedToManage(authData: authData) else {
                return .notAuthorized
            }

            BTDaemon.pause()
            return .success
        case .resumeActivity:
            guard self.isAuthorizedToManage(authData: authData) else {
                return .notAuthorized
            }

            BTDaemon.resume()
            return .success
        default:
            os_log("Unknown command: \(command.rawValue)")
            return .commFailed
        }
    }

    func getState(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    ) {
        Task { @MainActor in
            guard BTDaemon.supported else {
                reply([:])
                return
            }

            reply(BTDaemon.getState())
        }
    }

    func getSettings(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    ) {
        Task { @MainActor in
            guard BTDaemon.supported else {
                reply([:])
                return
            }

            reply(BTSettings.getSettings())
        }
    }

    func setSettings(
        authData: Data,
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        Task { @MainActor in
            //
            // Power state management functions may only be invoked when
            // supported.
            //
            guard BTDaemon.supported else {
                reply(BTError.unsupported.rawValue)
                return
            }

            guard self.hasChargingManagementLicense() else {
                reply(BTError.licenseRequired.rawValue)
                return
            }

            let authorized = self.checkRight(
                authData: authData,
                rightName: BTAuthorizationRights.manage
            )
            guard authorized else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            BTSettings.setSettings(settings: settings, reply: reply)
        }
    }

    private func checkRight(authData: Data?, rightName: String) -> Bool {
        let simpleAuth = SimpleAuth.fromData(authData: authData)
        guard let simpleAuth else {
            return false
        }

        return SimpleAuth.checkRight(
            simpleAuth: simpleAuth,
            rightName: rightName
        )
    }

    private func isAuthorizedToManage(authData: Data?) -> Bool {
        self.isAuthorized(
            authData: authData,
            rightName: BTAuthorizationRights.manage
        )
    }

    private func hasChargingManagementLicense() -> Bool {
        do {
            try BTLicenseController.requireCanManageCharging()
            return true
        } catch {
            return false
        }
    }

    private func isAuthorized(authData: Data?, rightName: String) -> Bool {
        self.checkRight(authData: authData, rightName: rightName)
    }
}
