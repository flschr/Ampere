//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCComm {
    @MainActor
    enum Power {
        private static let chargeKeys = [
            KeyControl.CHTE,
            KeyControl.CH0C
        ]
        private static let adapterKeys = [
            KeyControl.CHIE,
            KeyControl.CH0J
        ]

        private static var supportedChargeKeys: [KeyControl] = []
        private static var supportedAdapterKeys: [KeyControl] = []

        static var legacyChargingSupported: Bool {
            !self.supportedChargeKeys.isEmpty
        }

        static var adapterControlSupported: Bool {
            !self.supportedAdapterKeys.isEmpty
        }

        static func prepare() {
            //
            // Cache every known, well-formed key. Charging and adapter control
            // are separate capabilities on newer firmware.
            //
            self.supportedChargeKeys = self.chargeKeys.filter { key in
                SMCComm.keySupported(keyInfo: key.keyInfo, logErrors: false)
            }
            self.supportedAdapterKeys = self.adapterKeys.filter { key in
                SMCComm.keySupported(keyInfo: key.keyInfo, logErrors: false)
            }
        }

        static func enableCharging() -> Bool {
            return self.write(keys: self.supportedChargeKeys) { $0.onBytes }
        }

        static func disableCharging() -> Bool {
            return self.write(keys: self.supportedChargeKeys) { $0.offBytes }
        }

        static func isChargingDisabled() -> Bool {
            return self.containsDisabledKey(keys: self.supportedChargeKeys)
        }

        static func enablePowerAdapter() -> Bool {
            return self.write(keys: self.supportedAdapterKeys) { $0.onBytes }
        }

        static func disablePowerAdapter() -> Bool {
            return self.write(keys: self.supportedAdapterKeys) { $0.offBytes }
        }

        static func isPowerAdapterDisabled() -> Bool {
            return self.containsDisabledKey(keys: self.supportedAdapterKeys)
        }

        private static func write(
            keys: [KeyControl],
            bytes: (KeyControl) -> [UInt8]
        ) -> Bool {
            guard !keys.isEmpty else {
                return false
            }

            var success = true
            for key in keys {
                success =
                    SMCComm.writeKey(key: key.keyInfo.key, bytes: bytes(key)) &&
                    success
            }

            return success
        }

        private static func containsDisabledKey(keys: [KeyControl]) -> Bool {
            return keys.contains { key in
                let value = SMCComm.readKey(
                    key: key.keyInfo.key,
                    dataSize: key.onBytes.count
                )
                guard let value else {
                    return false
                }

                return value != key.onBytes
            }
        }
    }
}

private extension SMCComm.Power {
    private enum Keys {
        static let CHTE = SMCComm.KeyInfo(
            key: SMCComm.Key("C", "H", "T", "E"),
            info: SMCComm.KeyInfoData(
                dataSize: 4,
                dataType: SMCComm.KeyTypes.ui32,
                dataAttributes: 0xD4
            )
        )
        static let CH0C = SMCComm.KeyInfo(
            key: SMCComm.Key("C", "H", "0", "C"),
            info: SMCComm.KeyInfoData(
                dataSize: 1,
                dataType: SMCComm.KeyTypes.hex,
                dataAttributes: 0xD4
            )
        )
        static let CHIE = SMCComm.KeyInfo(
            key: SMCComm.Key("C", "H", "I", "E"),
            info: SMCComm.KeyInfoData(
                dataSize: 1,
                dataType: SMCComm.KeyTypes.hex,
                dataAttributes: 0xD4
            )
        )
        static let CH0J = SMCComm.KeyInfo(
            key: SMCComm.Key("C", "H", "0", "J"),
            info: SMCComm.KeyInfoData(
                dataSize: 1,
                dataType: SMCComm.KeyTypes.ui8,
                dataAttributes: 0xD4
            )
        )
    }

    private struct KeyControl {
        let keyInfo: SMCComm.KeyInfo
        let onBytes: [UInt8]
        let offBytes: [UInt8]

        static let CHTE = KeyControl(
            keyInfo: Keys.CHTE,
            onBytes: [0x00, 0x00, 0x00, 0x00],
            offBytes: [0x01, 0x00, 0x00, 0x00]
        )
        static let CH0C = KeyControl(
            keyInfo: Keys.CH0C,
            onBytes: [0x00],
            offBytes: [0x01]
        )
        static let CHIE = KeyControl(
            keyInfo: Keys.CHIE,
            onBytes: [0x00],
            offBytes: [0x08]
        )
        static let CH0J = KeyControl(
            keyInfo: Keys.CH0J,
            onBytes: [0x00],
            offBytes: [0x20]
        )
    }
}
