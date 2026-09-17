//
// Copyright (C) 2026 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
internal final class BTLowPowerThresholdControls: NSView {
    private let slider = NSSlider(frame: .zero)
    private let valueField = NSTextField(frame: .zero)

    var threshold: Int {
        get {
            let typedValue = Int(self.valueField.stringValue)
            return min(max(typedValue ?? Int(self.slider.doubleValue.rounded()), 0), 100)
        }
        set {
            let value = min(max(newValue, 0), 100)
            self.slider.doubleValue = Double(value)
            self.valueField.stringValue = String(value)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure()
    }

    private func configure() {
        let label = NSTextField(
            labelWithString: BTLocalization.Settings.lowPowerModeThreshold
        )
        let hint = NSTextField(
            labelWithString: BTLocalization.Settings.lowPowerModeOffHint
        )
        hint.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        hint.textColor = .secondaryLabelColor

        self.slider.minValue = 0
        self.slider.maxValue = 100
        self.slider.isContinuous = true
        self.slider.target = self
        self.slider.action = #selector(self.sliderChanged(_:))
        self.slider.setAccessibilityLabel(
            BTLocalization.Settings.lowPowerModeThreshold
        )

        self.valueField.alignment = .center
        self.valueField.target = self
        self.valueField.action = #selector(self.valueChanged(_:))
        self.valueField.setAccessibilityLabel(
            BTLocalization.Settings.lowPowerModeThreshold
        )

        let percentLabel = NSTextField(labelWithString: "%")
        percentLabel.alignment = .right

        for control in [label, hint, self.slider, self.valueField, percentLabel] {
            control.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(control)
        }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),

            self.slider.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            self.slider.heightAnchor.constraint(equalToConstant: 20),
            self.slider.trailingAnchor.constraint(
                equalTo: self.valueField.leadingAnchor,
                constant: -8
            ),

            self.valueField.widthAnchor.constraint(equalToConstant: 50),
            self.valueField.centerYAnchor.constraint(equalTo: self.slider.centerYAnchor),
            self.valueField.trailingAnchor.constraint(
                equalTo: percentLabel.leadingAnchor,
                constant: -5
            ),

            percentLabel.widthAnchor.constraint(equalToConstant: 12),
            percentLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: self.slider.centerYAnchor),

            hint.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hint.topAnchor.constraint(equalTo: self.slider.bottomAnchor, constant: 8),
            hint.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])

        self.threshold = Int(BTSettingsInfo.Defaults.lowPowerModeThreshold)
    }

    @objc private func sliderChanged(_: NSSlider) {
        self.threshold = Int(self.slider.doubleValue.rounded())
    }

    @objc private func valueChanged(_: NSTextField) {
        self.threshold = self.threshold
    }
}
