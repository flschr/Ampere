//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCComm {
    @MainActor
    enum FirmwareChargeLimit {
        struct State: Equatable {
            let active: Bool
            let lower: UInt8
            let upper: UInt8
        }

        private static let activationKey = SMCComm.Key("b", "f", "F", "0")
        private static let upperKey = SMCComm.Key("b", "f", "D", "0")
        private static let lowerKey = SMCComm.Key("b", "f", "E", "0")

        static var supported: Bool {
            self.hasKey(self.activationKey, size: 1) &&
                self.hasKey(self.upperKey, size: 4) &&
                self.hasKey(self.lowerKey, size: 4)
        }

        static func read() -> State? {
            guard
                let activation = SMCComm.readKey(
                    key: self.activationKey,
                    dataSize: 1
                )?.first,
                let upper = self.readLimit(key: self.upperKey),
                let lower = self.readLimit(key: self.lowerKey)
            else {
                return nil
            }
            guard activation == 0x00 || activation == 0x02 else {
                return nil
            }

            return State(
                active: activation == 0x02,
                lower: lower,
                upper: upper
            )
        }

        static func apply(lower: UInt8, upper: UInt8) -> Bool {
            guard lower < upper, upper <= 100 else {
                return false
            }
            let desiredState = State(
                active: true,
                lower: lower,
                upper: upper
            )
            if self.read() == desiredState {
                return true
            }

            guard
                SMCComm.writeKey(key: self.activationKey, bytes: [0x00]),
                SMCComm.writeKey(
                    key: self.upperKey,
                    bytes: self.limitBytes(upper)
                ),
                SMCComm.writeKey(
                    key: self.lowerKey,
                    bytes: self.limitBytes(lower)
                ),
                SMCComm.writeKey(key: self.activationKey, bytes: [0x02])
            else {
                return false
            }

            return self.read() == desiredState
        }

        static func disable() -> Bool {
            if self.read()?.active == false {
                return true
            }
            guard SMCComm.writeKey(key: self.activationKey, bytes: [0x00]) else {
                return false
            }
            return self.read()?.active == false
        }

        static func restore(_ state: State) -> Bool {
            if self.read() == state {
                return true
            }
            guard
                SMCComm.writeKey(key: self.activationKey, bytes: [0x00]),
                SMCComm.writeKey(
                    key: self.upperKey,
                    bytes: self.limitBytes(state.upper)
                ),
                SMCComm.writeKey(
                    key: self.lowerKey,
                    bytes: self.limitBytes(state.lower)
                ),
                SMCComm.writeKey(
                    key: self.activationKey,
                    bytes: [state.active ? 0x02 : 0x00]
                )
            else {
                return false
            }

            return self.read() == state
        }

        static func limitBytes(_ value: UInt8) -> [UInt8] {
            [value, 0x00, 0x00, 0x00]
        }

        private static func hasKey(_ key: SMCComm.Key, size: UInt32) -> Bool {
            SMCComm.getKeyInfo(key: key, logErrors: false)?.dataSize == size
        }

        private static func readLimit(key: SMCComm.Key) -> UInt8? {
            guard
                let bytes = SMCComm.readKey(key: key, dataSize: 4),
                bytes.count == 4,
                bytes[1...].allSatisfy({ $0 == 0 }),
                bytes[0] <= 100
            else {
                return nil
            }

            return bytes[0]
        }
    }
}
