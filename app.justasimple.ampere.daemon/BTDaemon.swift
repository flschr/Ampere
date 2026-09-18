//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import IOKit.pwr_mgt

@main
@MainActor
internal enum BTDaemon {
    private(set) static var supported = false
    private static var enabled = false

    private static var uniqueId: Data? = nil

    /// SIGTERM source signal. Needs to be preserved for the program lifetime.
    private static var termSource: DispatchSourceSignal? = nil

    static func getUniqueId() -> Data? {
        return self.uniqueId
    }

    static func getState() -> [String: NSObject & Sendable] {
        guard enabled else {
            return BTBatteryState(enabled: false).payload
        }

        let chargingDisabled = BTPowerState.isChargingDisabled()
        let connected = BTPowerEvents.unlimitedPower
        let powerDisabled = BTPowerState.isPowerAdapterDisabled()
        let batteryPercent = BTPowerState.getPercentRemaining().0
        let progress = BTPowerEvents.getChargingProgress()
        let mode = BTPowerEvents.chargingMode
        let maxCharge = BTSettings.maxCharge
        let thermallyLimited = BTPowerEvents.thermallyLimited

        return BTBatteryState(
            enabled: true,
            powerDisabled: powerDisabled,
            connected: connected,
            chargingDisabled: chargingDisabled,
            batteryPercent: Int(batteryPercent),
            progress: progress,
            chargingMode: mode,
            maxCharge: Int(maxCharge),
            thermallyLimited: thermallyLimited,
            capabilities: BTChargeController.capabilities
        ).payload
    }

    private static func start() throws {
        try BTPowerEvents.start()

        let callback: IOServiceInterestCallback = { refCon, service, messageType, messageArgument in
            if messageType == PowerEvents.kIOMessageCanSystemSleep ||
               messageType == PowerEvents.kIOMessageSystemWillSleep {
                IOAllowPowerChange(
                    PowerEvents.root_port,
                    Int(bitPattern: messageArgument)
                )
            } else if messageType == PowerEvents.kIOMessageSystemHasPoweredOn {
                BTPowerEvents.wakeFromSleep()
            }
        }

        let success = PowerEvents.register(callback: callback)
        guard success else {
            os_log("Error registering system power event")
            BTPowerEvents.stop()
            throw BTError.unknown
        }
    }

    static func resume() {
        guard !self.enabled else {
            return
        }

        do {
            try self.start()
            self.enabled = true
        } catch {
            //
            // If we got unsupported here, this would contradict earlier
            // success. Force a restart just in case.
            //
            os_log("Power events start failed")
            exit(-1)
        }
    }

    static func pause() {
        guard self.enabled else {
            return
        }

        PowerEvents.deregister()

        self.enabled = false
        BTPowerEvents.stop()
    }

    private static func main() {
        //
        // Cache the unique ID immediately, as this is not safe against
        // modifications of the daemon on-disk. This ID must not be used for
        // security-criticial purposes.
        //
        self.uniqueId = CSIdentification.getUniqueIdSelf()

        BTSettings.readDefaults()

        GlobalSleep.restoreOnStart()

        do {
            try self.start()
            self.enabled = true
            self.supported = true

            let termSource = DispatchSource.makeSignalSource(
                signal: SIGTERM,
                queue: DispatchQueue.main
            )
            termSource.setEventHandler {
                BTPowerEvents.exit()
                exit(0)
            }
            termSource.resume()
            //
            // Preserve termSource globally, so it is not deallocated.
            //
            self.termSource = termSource
            //
            // Ignore SIGTERM to catch it above and gracefully stop the service.
            //
            signal(SIGTERM, SIG_IGN)

            let status = SimpleAuth.duplicateRight(
                rightName: BTAuthorizationRights.manage,
                templateName: kAuthorizationRuleAuthenticateAsAdmin,
                comment: "Used by \(BT_DAEMON_ID) to allow access to its privileged functions",
                timeout: 300
            )
            if status != errSecSuccess {
                os_log("Error adding manage right: \(status)")
            }
        } catch BTError.unsupported {
            //
            // Still run the XPC server if the machine is unsupported to cleanly
            // uninstall the daemon, but don't initialize the rest of the stack.
            //
            self.supported = false
        } catch {
            os_log("Power events start failed")
            exit(-1)
        }

        BTDaemonXPCServer.start()

        dispatchMain()
    }
}
