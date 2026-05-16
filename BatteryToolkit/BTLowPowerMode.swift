//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLowPowerMode {
    private static let pmsetURL = URL(fileURLWithPath: "/usr/bin/pmset")

    static func isEnabled() throws -> Bool {
        let activeSettings = try self.powerSettings(arguments: ["-g"])
        if let powerMode = activeSettings["powermode"] {
            return powerMode == "1"
        }
        if let lowPowerMode = activeSettings["lowpowermode"] {
            return lowPowerMode != "0"
        }

        throw BTError.malformedData
    }

    static func setEnabled(_ enabled: Bool) throws {
        do {
            try self.setPowerMode(enabled ? "1" : "0")
        } catch {
            try self.setLowPowerMode(enabled)
        }
    }

    private static func setPowerMode(_ value: String) throws {
        try self.runPMSet(arguments: ["-b", "powermode", value])
        try self.runPMSet(arguments: ["-c", "powermode", value])
    }

    private static func setLowPowerMode(_ enabled: Bool) throws {
        try self.runPMSet(arguments: [
            "-a",
            "lowpowermode",
            enabled ? "1" : "0",
        ])
    }

    private static func powerSettings(arguments: [String]) throws -> [String: String] {
        let output = try self.runPMSet(arguments: arguments)
        var settings: [String: String] = [:]

        for line in output.components(separatedBy: .newlines) {
            let components = line.split(separator: " ")
            guard let key = components.first,
                  let value = components.last
            else {
                continue
            }

            settings[String(key)] = String(value)
        }

        return settings
    }

    @discardableResult private static func runPMSet(arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = self.pmsetURL
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            throw BTError.commFailed
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw BTError.commFailed
        }

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let string = String(data: output, encoding: .utf8) else {
            throw BTError.malformedData
        }

        return string
    }
}
