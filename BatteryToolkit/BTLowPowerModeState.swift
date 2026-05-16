//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLowPowerModeSettingKey: String {
    case lowPowerMode = "lowpowermode"
    case powerMode = "powermode"

    func isEnabled(value: String) -> Bool {
        switch self {
        case .lowPowerMode:
            return value != "0"
        case .powerMode:
            return value == "1"
        }
    }

    func setValue(enabled: Bool) -> String {
        enabled ? "1" : "0"
    }
}

internal enum BTLowPowerModeProfile: String, CaseIterable {
    case battery = "Battery Power"
    case ac = "AC Power"
}

internal struct BTLowPowerModeState: Equatable {
    let key: BTLowPowerModeSettingKey
    let values: [BTLowPowerModeProfile: String]

    var isEnabled: Bool {
        guard let value = self.values[.battery] else {
            return self.values.values.first.map {
                self.key.isEnabled(value: $0)
            } ?? false
        }

        return self.key.isEnabled(value: value)
    }

    var hasEnabledProfile: Bool {
        self.values.values.contains { self.key.isEnabled(value: $0) }
    }

    func matches(enabled: Bool) -> Bool {
        if enabled {
            return self.isEnabled && !self.isEnabled(profile: .ac)
        }

        return !self.hasEnabledProfile
    }

    private func isEnabled(profile: BTLowPowerModeProfile) -> Bool {
        self.values[profile].map {
            self.key.isEnabled(value: $0)
        } ?? false
    }
}

internal enum BTLowPowerModeParser {
    static func state(
        customOutput: String,
        activeOutput: String?
    ) throws -> BTLowPowerModeState {
        let customSettings = self.customPowerSettings(from: customOutput)
        if let state = self.state(for: .lowPowerMode, in: customSettings) {
            return state
        }
        if let state = self.state(for: .powerMode, in: customSettings) {
            return state
        }

        if let activeOutput {
            let activeSettings = self.activePowerSettings(from: activeOutput)
            if let value = activeSettings[.lowPowerMode] {
                return BTLowPowerModeState(
                    key: .lowPowerMode,
                    values: [.battery: value]
                )
            }
            if let value = activeSettings[.powerMode] {
                return BTLowPowerModeState(
                    key: .powerMode,
                    values: [.battery: value]
                )
            }
        }

        throw BTError.malformedData
    }

    static func customPowerSettings(
        from output: String
    ) -> [BTLowPowerModeProfile: [BTLowPowerModeSettingKey: String]] {
        var settings: [BTLowPowerModeProfile: [BTLowPowerModeSettingKey: String]] = [:]
        var profile: BTLowPowerModeProfile?

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix(":") {
                profile = BTLowPowerModeProfile(
                    rawValue: String(trimmed.dropLast())
                )
                continue
            }

            guard let profile,
                  let (key, value) = self.powerSetting(from: trimmed)
            else {
                continue
            }

            settings[profile, default: [:]][key] = value
        }

        return settings
    }

    static func activePowerSettings(
        from output: String
    ) -> [BTLowPowerModeSettingKey: String] {
        var settings: [BTLowPowerModeSettingKey: String] = [:]
        for line in output.components(separatedBy: .newlines) {
            guard let (key, value) = self.powerSetting(from: line) else {
                continue
            }

            settings[key] = value
        }

        return settings
    }

    static func powerModeCapabilities(
        from output: String
    ) -> Set<BTLowPowerModeSettingKey> {
        Set(output.split(whereSeparator: { $0.isWhitespace }).compactMap {
            BTLowPowerModeSettingKey(rawValue: String($0).lowercased())
        })
    }

    private static func state(
        for key: BTLowPowerModeSettingKey,
        in settings: [BTLowPowerModeProfile: [BTLowPowerModeSettingKey: String]]
    ) -> BTLowPowerModeState? {
        let values = settings.reduce(into: [BTLowPowerModeProfile: String]()) {
            if let value = $1.value[key] {
                $0[$1.key] = value
            }
        }

        guard !values.isEmpty else {
            return nil
        }

        return BTLowPowerModeState(key: key, values: values)
    }

    private static func powerSetting(
        from line: String
    ) -> (BTLowPowerModeSettingKey, String)? {
        let components = line.split(whereSeparator: { $0.isWhitespace })
        guard let keyComponent = components.first,
              let value = components.last,
              let key = BTLowPowerModeSettingKey(
                  rawValue: String(keyComponent).lowercased()
              )
        else {
            return nil
        }

        return (key, String(value))
    }
}
