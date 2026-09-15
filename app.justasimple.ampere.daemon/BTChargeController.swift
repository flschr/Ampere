//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import os.log

@MainActor
internal enum BTChargeController {
    private(set) static var capabilities = BTPowerCapabilities.legacy

    private static var systemClient: BTSystemChargeLimitClient?
    private static var firmwareOriginalState: SMCComm.FirmwareChargeLimit.State?

    static var usesLegacyControl: Bool {
        self.capabilities.chargeControlMode == .legacySMC
    }

    static func start() -> Bool {
        self.systemClient = nil
        self.firmwareOriginalState = nil
        self.capabilities = .legacy
        SMCComm.Power.prepare()
        SMCComm.MagSafe.prepare()
        let adapterControl = SMCComm.Power.adapterControlSupported

        if SMCComm.FirmwareChargeLimit.supported,
           let originalState = SMCComm.FirmwareChargeLimit.read() {
            self.firmwareOriginalState = originalState
            self.capabilities = .firmwareManaged(
                adapterControl: adapterControl,
                magSafeSync: SMCComm.MagSafe.supported
            )
            os_log("Using firmware-managed charge limits")
            return true
        }

        if SMCComm.Power.legacyChargingSupported {
            self.capabilities = .legacy(
                adapterControl: adapterControl,
                magSafeSync: SMCComm.MagSafe.supported
            )
            return true
        }

        if let client = BTSystemChargeLimitClient.make(),
           let capabilities = BTPowerCapabilities.systemManaged(
               adapterControl: adapterControl,
               magSafeSync: SMCComm.MagSafe.supported,
               availableLimits: client.availableLimits
           ) {
            self.systemClient = client
            self.capabilities = capabilities
            os_log("Using system-managed charge limits")
            return true
        }

        return false
    }

    static func normalizedLimits(
        minCharge: UInt8,
        maxCharge: UInt8
    ) -> (min: UInt8, max: UInt8) {
        let normalizedMax = UInt8(
            self.capabilities.nearestSupported(maxCharge: Int(maxCharge))
        )

        switch self.capabilities.chargeControlMode {
        case .legacySMC:
            return (minCharge, normalizedMax)
        case .firmwareSMC:
            return (min(minCharge, normalizedMax > 0 ? normalizedMax - 1 : 0), normalizedMax)
        case .systemManaged:
            return (min(minCharge, normalizedMax), normalizedMax)
        }
    }

    static func applyStandardLimit(minCharge: UInt8, maxCharge: UInt8) -> Bool {
        switch self.capabilities.chargeControlMode {
        case .legacySMC:
            return true
        case .firmwareSMC:
            if maxCharge == 100 {
                return SMCComm.FirmwareChargeLimit.disable()
            }
            return SMCComm.FirmwareChargeLimit.apply(
                lower: minCharge,
                upper: maxCharge
            )
        case .systemManaged:
            return self.systemClient?.apply(limit: maxCharge) == true
        }
    }

    static func requestFullCharge() -> Bool {
        switch self.capabilities.chargeControlMode {
        case .legacySMC:
            return true
        case .firmwareSMC:
            return SMCComm.FirmwareChargeLimit.disable()
        case .systemManaged:
            return self.systemClient?.apply(limit: 100) == true
        }
    }

    static func restoreOriginalState() -> Bool {
        defer {
            self.systemClient = nil
            self.firmwareOriginalState = nil
        }

        switch self.capabilities.chargeControlMode {
        case .legacySMC:
            return true
        case .firmwareSMC:
            guard let state = self.firmwareOriginalState else {
                return false
            }
            return SMCComm.FirmwareChargeLimit.restore(state)
        case .systemManaged:
            return self.systemClient?.restoreOriginalState() == true
        }
    }
}
