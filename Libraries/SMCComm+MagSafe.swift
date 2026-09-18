//
// Copyright (C) 2024 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCComm {
    @MainActor
    enum MagSafe {
        private(set) static var supported = false

        static func prepare() {
            //
            // Ensure all required SMC keys are present and well-formed.
            //
            self.supported = SMCComm.keySupported(keyInfo: self.Keys.ACLC)
        }

        static func setSystem() -> Bool {
            guard self.supported else {
                return false
            }

            return SMCComm.writeKey(key: self.Keys.ACLC.key, bytes: [0x00])
        }
    }
}

private extension SMCComm.MagSafe {
    private enum Keys {
        static let ACLC = SMCComm.KeyInfo(
            key: SMCComm.Key("A", "C", "L", "C"),
            info: SMCComm.KeyInfoData(
                dataSize: 1,
                dataType: SMCComm.KeyTypes.ui8,
                dataAttributes: 0xD4
            )
        )
    }

}
