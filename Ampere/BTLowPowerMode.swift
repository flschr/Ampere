//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLowPowerMode {
    private static let pmsetURL = URL(fileURLWithPath: "/usr/bin/pmset")

    static func isEnabled() throws -> Bool {
        try self.readState().isEnabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        let key = try self.preferredWriteKey()
        try self.set(key: key, enabled: enabled)

        let state = try self.readState()
        guard state.key == key, state.matches(enabled: enabled) else {
            throw BTError.commFailed
        }
    }

    @discardableResult static func disableIfEnabled() throws -> Bool {
        let state = try self.readState()
        guard state.hasEnabledProfile else {
            return false
        }

        try self.set(key: state.key, enabled: false)

        let updatedState = try self.readState()
        guard updatedState.key == state.key,
              updatedState.matches(enabled: false)
        else {
            throw BTError.commFailed
        }

        return true
    }

    @discardableResult static func normalizeForBatteryPower() throws -> Bool {
        let state = try self.readState()
        guard state.hasEnabledProfile else {
            return false
        }

        try self.set(key: state.key, enabled: state.isEnabled)

        let updatedState = try self.readState()
        guard updatedState.key == state.key,
              updatedState.matches(enabled: state.isEnabled)
        else {
            throw BTError.commFailed
        }

        return true
    }

    internal static func state(
        customOutput: String,
        activeOutput: String?
    ) throws -> BTLowPowerModeState {
        try BTLowPowerModeParser.state(
            customOutput: customOutput,
            activeOutput: activeOutput
        )
    }

    internal static func powerModeCapabilities(
        from output: String
    ) -> Set<BTLowPowerModeSettingKey> {
        BTLowPowerModeParser.powerModeCapabilities(from: output)
    }

    private static func readState() throws -> BTLowPowerModeState {
        try BTLowPowerModeParser.state(
            customOutput: self.runPMSet(arguments: ["-g", "custom"]),
            activeOutput: self.runPMSet(arguments: ["-g"])
        )
    }

    private static func preferredWriteKey() throws -> BTLowPowerModeSettingKey {
        if let capabilities = try? self.runPMSet(arguments: ["-g", "cap"]) {
            let keys = BTLowPowerModeParser.powerModeCapabilities(
                from: capabilities
            )
            if keys.contains(.lowPowerMode) {
                return .lowPowerMode
            }
            if keys.contains(.powerMode) {
                return .powerMode
            }
        }

        return try self.readState().key
    }

    private static func set(
        key: BTLowPowerModeSettingKey,
        enabled: Bool
    ) throws {
        let value = key.setValue(enabled: enabled)
        if enabled {
            try self.runPMSet(arguments: ["-b", key.rawValue, value])
            try self.runPMSet(
                arguments: ["-c", key.rawValue, key.setValue(enabled: false)]
            )
        } else {
            try self.runPMSet(arguments: ["-a", key.rawValue, value])
        }
        self.refreshPowerSettings()
    }

    private static func refreshPowerSettings() {
        _ = try? self.runPMSet(arguments: ["touch"])
    }

    @discardableResult private static func runPMSet(arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = self.pmsetURL
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw BTError.commFailed
        }

        process.waitUntilExit()
        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        _ = errorPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            throw BTError.commFailed
        }

        guard let string = String(data: output, encoding: .utf8) else {
            throw BTError.malformedData
        }

        return string
    }
}
