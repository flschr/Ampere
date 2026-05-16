//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLowPowerMode {
    private static let pmsetURL = URL(fileURLWithPath: "/usr/bin/pmset")

    static func isEnabled() throws -> Bool {
        let output = try self.runPMSet(arguments: ["-g"])
        for line in output.components(separatedBy: .newlines) {
            let components = line.split(separator: " ")
            guard components.first == "lowpowermode",
                  let value = components.last
            else {
                continue
            }

            return value != "0"
        }

        throw BTError.malformedData
    }

    static func setEnabled(_ enabled: Bool) throws {
        _ = try self.runPMSet(arguments: [
            "-a",
            "lowpowermode",
            enabled ? "1" : "0",
        ])
    }

    private static func runPMSet(arguments: [String]) throws -> String {
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
