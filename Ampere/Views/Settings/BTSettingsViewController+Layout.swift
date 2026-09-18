//
// Copyright (C) 2026 René Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
extension BTSettingsViewController {
    func addInitialFocusView() {
        self.initialFocusView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.initialFocusView)
        NSLayoutConstraint.activate([
            self.initialFocusView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.initialFocusView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.initialFocusView.widthAnchor.constraint(equalToConstant: 0),
            self.initialFocusView.heightAnchor.constraint(equalToConstant: 0),
        ])
    }

    func configurePowerTabTextFields() {
        guard let powerView = self.powerTab.view else {
            assertionFailure()
            return
        }
        for textField in powerView.allTextFields {
            textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            guard !textField.isEditable else {
                continue
            }
            if textField.font?.pointSize ?? 0 < NSFont.systemFontSize {
                textField.cell?.wraps = true
                textField.lineBreakMode = .byWordWrapping
            } else {
                textField.cell?.wraps = false
                textField.lineBreakMode = .byTruncatingTail
            }
        }
    }

    func addAboutButton() {
        let aboutButton = NSButton(
            title: "",
            target: self,
            action: #selector(self.aboutButtonAction(_:))
        )
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        aboutButton.bezelStyle = .circular
        aboutButton.image = NSImage(
            systemSymbolName: "info.circle",
            accessibilityDescription: BTLocalization.Settings.About.infoButtonAccessibilityLabel
        )
        aboutButton.imagePosition = .imageOnly
        aboutButton.toolTip = BTLocalization.Settings.About.infoButtonAccessibilityLabel
        aboutButton.setAccessibilityLabel(
            BTLocalization.Settings.About.infoButtonAccessibilityLabel
        )
        self.view.addSubview(aboutButton)
        NSLayoutConstraint.activate([
            aboutButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            aboutButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            aboutButton.widthAnchor.constraint(equalToConstant: 24),
            aboutButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @objc private func aboutButtonAction(_: NSButton) {
        self.presentAsSheet(BTAboutInfoViewController())
    }

    func addOptimizedChargingWarning() {
        let warning = NSTextField(
            labelWithString: BTLocalization.Settings.optimizedChargingWarning
        )
        warning.translatesAutoresizingMaskIntoConstraints = false
        warning.textColor = .systemOrange
        warning.lineBreakMode = .byTruncatingTail
        warning.maximumNumberOfLines = 1
        warning.isHidden = true
        self.view.addSubview(warning)
        NSLayoutConstraint.activate([
            warning.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            warning.trailingAnchor.constraint(
                lessThanOrEqualTo: self.view.trailingAnchor,
                constant: -20
            ),
            warning.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -52),
        ])
        self.optimizedChargingWarning = warning
    }

    func addLowPowerThresholdControls() {
        guard let powerView = self.powerTab.view else {
            return
        }
        let separator = NSBox(frame: .zero)
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        powerView.addSubview(separator)

        self.lowPowerThresholdControls.translatesAutoresizingMaskIntoConstraints = false
        powerView.addSubview(self.lowPowerThresholdControls)
        self.legacySectionTopConstraint = separator.topAnchor.constraint(
            equalTo: self.chargingSleepDescription.bottomAnchor,
            constant: 12
        )
        self.managedSectionTopConstraint = separator.topAnchor.constraint(
            equalTo: self.maxChargeSlider.bottomAnchor,
            constant: 20
        )
        self.chargingSleepDescription.isHidden = true
        self.managedSectionTopConstraint?.isActive = true
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: powerView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: powerView.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 1),
            self.lowPowerThresholdControls.leadingAnchor.constraint(
                equalTo: powerView.leadingAnchor,
                constant: 20
            ),
            self.lowPowerThresholdControls.trailingAnchor.constraint(
                equalTo: powerView.trailingAnchor,
                constant: -20
            ),
            self.lowPowerThresholdControls.topAnchor.constraint(
                equalTo: separator.bottomAnchor,
                constant: 12
            ),
        ])
    }
}

internal final class BTSettingsInitialFocusView: NSView {
    override var acceptsFirstResponder: Bool { true }
}

private extension NSView {
    var allTextFields: [NSTextField] {
        self.subviews.flatMap { subview in
            ([subview as? NSTextField].compactMap { $0 }) + subview.allTextFields
        }
    }
}
