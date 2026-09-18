//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTSettingsViewController: NSViewController {
    private static let contentSize = NSSize(width: 520, height: 390)

    private var currentSettings: [String: NSObject & Sendable]? = nil
    private var capabilities = BTPowerCapabilities.legacy
    private weak var cancelButton: NSButton? = nil
    private var optimizedChargingWarning: NSTextField? = nil
    private let initialFocusView = BTSettingsInitialFocusView()

    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var powerTab: NSTabViewItem!

    @IBOutlet private var minChargeTextField: NSTextField!
    @IBOutlet private var minChargeSlider: NSSlider!

    @IBOutlet private var maxChargeTextField: NSTextField!
    @IBOutlet private var maxChargeSlider: NSSlider!
    @IBOutlet private var chargingSleepDescription: NSTextField!

    private let lowPowerThresholdControls = BTLowPowerThresholdControls()

    private var minChargeVal = BTSettingsInfo.Defaults.minCharge
    @objc private dynamic var minChargeNum: NSNumber {
        get {
            return NSNumber(value: self.minChargeVal)
        }

        set {
            let value = newValue.intValue
            //
            // For clamping, the assignment needs to be async, because otherwise
            // the source control does not get notified of the update. We cannot
            // change the values of the UI controls directly, because this
            // causes the NSSlider to sometimes visually desync with its value.
            //
            if value < BTSettingsInfo.Bounds.minChargeMin {
                Task {
                    self.minChargeNum = NSNumber(
                        value: BTSettingsInfo.Bounds.minChargeMin
                    )
                }
            } else if value > 100 {
                Task {
                    self.minChargeNum = NSNumber(value: 100)
                }
            } else {
                self.minChargeVal = UInt8(value)
                //
                // Clamp the maximum charge to be at least the minimum charge.
                //
                if self.maxChargeVal < self.minChargeVal {
                    self.maxChargeNum = self.minChargeNum
                }
            }
        }
    }

    private var maxChargeVal = BTSettingsInfo.Defaults.maxCharge
    @objc private dynamic var maxChargeNum: NSNumber {
        get {
            return NSNumber(value: self.maxChargeVal)
        }

        set {
            let value = newValue.intValue
            let normalized = self.capabilities.nearestSupported(
                maxCharge: value
            )
            //
            // See minChargeNum for an explanation.
            //
            if value != normalized {
                Task {
                    self.maxChargeNum = NSNumber(value: normalized)
                }
            } else {
                self.maxChargeVal = UInt8(value)
                //
                // Clamp the maximum charge to be at least the minimum charge.
                //
                if self.maxChargeVal < self.minChargeVal {
                    self.minChargeNum = self.maxChargeNum
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.widthAnchor.constraint(
            equalToConstant: Self.contentSize.width
        ).isActive = true
        self.view.heightAnchor.constraint(
            equalToConstant: Self.contentSize.height
        ).isActive = true
        self.tabView.selectTabViewItem(self.powerTab)
        self.tabView.heightAnchor.constraint(equalToConstant: 321).isActive = true
        self.addInitialFocusView()
        self.configurePowerTabTextFields()
        self.cancelButton = self.view.subviews.compactMap {
            $0 as? NSButton
        }.first {
            $0.action == #selector(self.cancelButtonAction(_:))
        }
        self.addAboutButton()
        self.addOptimizedChargingWarning()
        self.addLowPowerThresholdControls()
    }

    @IBAction private func cancelButtonAction(_: NSButton) {
        self.view.window?.windowController?.close()
    }

    @IBAction private func doneButtonAction(_: NSButton) {
        let settings: [String: NSObject & Sendable]
        do {
            settings = try BTSettingsPayloadFactory.make(
                minCharge: self.minChargeNum.intValue,
                maxCharge: self.maxChargeNum.intValue,
                lowPowerModeThreshold: self.lowPowerThresholdControls.threshold,
                capabilities: self.capabilities
            )
        } catch {
            BTErrorHandler.errorHandler(
                error: error,
                window: self.view.window
            )
            return
        }
        //
        // Submit the settings to the daemon only when they changed.
        //
        guard BTSettingsPayloadFactory.changed(
            settings,
            from: self.currentSettings
        )
        else {
            os_log("Power settings have not changed, ignoring")
            self.view.window?.windowController?.close()

            return
        }

        Task {
            do {
                try await BTActions.setSettings(settings: settings)
                self.view.window?.windowController?.close()
            } catch {
                BTErrorHandler.errorHandler(
                    error: error,
                    window: self.view.window
                )
            }
        }
    }

    @objc private func aboutButtonAction(_: NSButton) {
        self.presentAsSheet(BTAboutInfoViewController())
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        self.view.window?.initialFirstResponder = self.initialFocusView

        Task {
            await self.initPowerState()
            self.view.window?.center()
            //
            // Activate the app when the Settings window is shown, e.g., when
            // invoked from the Menu Bar Extra.
            //
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        self.view.window?.makeFirstResponder(self.initialFocusView)
    }

    private func addInitialFocusView() {
        self.initialFocusView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.initialFocusView)

        NSLayoutConstraint.activate([
            self.initialFocusView.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor
            ),
            self.initialFocusView.topAnchor.constraint(
                equalTo: self.view.topAnchor
            ),
            self.initialFocusView.widthAnchor.constraint(equalToConstant: 0),
            self.initialFocusView.heightAnchor.constraint(equalToConstant: 0),
        ])
    }

    private func configurePowerTabTextFields() {
        guard let powerView = self.powerTab.view else {
            assertionFailure()
            return
        }

        for textField in powerView.allTextFields {
            textField.setContentCompressionResistancePriority(
                .defaultLow,
                for: .horizontal
            )

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

    private func addAboutButton() {
        let aboutButton = NSButton(
            title: "",
            target: self,
            action: #selector(self.aboutButtonAction(_:))
        )
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        aboutButton.bezelStyle = .circular
        aboutButton.image = NSImage(
            systemSymbolName: "info.circle",
            accessibilityDescription:
                BTLocalization.Settings.About.infoButtonAccessibilityLabel
        )
        aboutButton.imagePosition = .imageOnly
        aboutButton.toolTip =
            BTLocalization.Settings.About.infoButtonAccessibilityLabel
        aboutButton.setAccessibilityLabel(
            BTLocalization.Settings.About.infoButtonAccessibilityLabel
        )

        self.view.addSubview(aboutButton)

        NSLayoutConstraint.activate([
            aboutButton.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: 20
            ),
            aboutButton.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor,
                constant: -20
            ),
            aboutButton.widthAnchor.constraint(equalToConstant: 24),
            aboutButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func setMinCharge(value: Int) {
        self.minChargeNum = NSNumber(value: value)
    }

    private func setMaxCharge(value: Int) {
        self.maxChargeNum = NSNumber(value: value)
    }

    private func addOptimizedChargingWarning() {
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
            warning.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: 20
            ),
            warning.trailingAnchor.constraint(
                lessThanOrEqualTo: self.view.trailingAnchor,
                constant: -20
            ),
            warning.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor,
                constant: -52
            ),
        ])

        self.optimizedChargingWarning = warning
    }

    private func addLowPowerThresholdControls() {
        guard let powerView = self.powerTab.view else {
            return
        }

        self.lowPowerThresholdControls.translatesAutoresizingMaskIntoConstraints = false
        powerView.addSubview(self.lowPowerThresholdControls)
        NSLayoutConstraint.activate([
            self.lowPowerThresholdControls.leadingAnchor.constraint(
                equalTo: powerView.leadingAnchor,
                constant: 20
            ),
            self.lowPowerThresholdControls.trailingAnchor.constraint(
                equalTo: powerView.trailingAnchor,
                constant: -20
            ),
            self.lowPowerThresholdControls.topAnchor.constraint(
                equalTo: self.chargingSleepDescription.bottomAnchor,
                constant: 12
            ),
            self.lowPowerThresholdControls.bottomAnchor.constraint(
                equalTo: powerView.bottomAnchor,
                constant: -20
            ),
        ])
    }

    private func updateOptimizedChargingWarning() {
        self.optimizedChargingWarning?.isHidden =
            self.capabilities.chargeControlMode == .systemManaged ||
            !IOPSPrivate.OptimizedBatteryChargingEngaged()
    }

    private func initPowerState() async {
        do {
            let settings = try await BTActions.getSettings()
            let parsedSettings = try BTBatterySettings(payload: settings)
            self.currentSettings = settings
            self.capabilities = parsedSettings.capabilities
            self.configureCapabilities()
            self.updateOptimizedChargingWarning()

            self.setMinCharge(value: parsedSettings.minCharge)
            self.setMaxCharge(value: parsedSettings.maxCharge)
            self.lowPowerThresholdControls.threshold =
                parsedSettings.lowPowerModeThreshold

        } catch {
            BTErrorHandler.errorHandler(error: error)
        }
    }

    private func configureCapabilities() {
        let customRange = self.capabilities.customChargeRange
        self.minChargeTextField.isEnabled = customRange
        self.minChargeSlider.isEnabled = customRange

        self.maxChargeSlider.minValue = Double(
            self.capabilities.minimumMaxCharge
        )
        self.maxChargeSlider.numberOfTickMarks =
            (100 - self.capabilities.minimumMaxCharge) /
            self.capabilities.maxChargeStep + 1
        self.maxChargeSlider.allowsTickMarkValuesOnly =
            self.capabilities.maxChargeStep > 1

    }
}

private final class BTSettingsInitialFocusView: NSView {
    override var acceptsFirstResponder: Bool {
        true
    }
}

private extension NSView {
    var allTextFields: [NSTextField] {
        self.subviews.flatMap { subview in
            ([subview as? NSTextField].compactMap { $0 }) +
                subview.allTextFields
        }
    }
}
