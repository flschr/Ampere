//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTSettingsViewController: NSViewController {
    private static let contentSize = NSSize(width: 520, height: 453)

    private var currentSettings: [String: NSObject & Sendable]? = nil
    private var presetLabel: NSTextField? = nil
    private var presetControl: NSSegmentedControl? = nil
    private weak var cancelButton: NSButton? = nil
    private var optimizedChargingWarning: NSTextField? = nil
    private let initialFocusView = BTSettingsInitialFocusView()
    
    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var powerTab: NSTabViewItem!
    
    @IBOutlet private var minChargeTextField: NSTextField!
    @IBOutlet private var minChargeSlider: NSSlider!
    
    @IBOutlet private var maxChargeTextField: NSTextField!
    @IBOutlet private var maxChargeSlider: NSSlider!
    
    @IBOutlet private var adapterSleepSwitch: NSSwitch!
    @IBOutlet private var magSafeSyncSwitch: NSSwitch!
    
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
            // caues the NSSlider to sometimes visually desync with its value.
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
            //
            // See minChargeNum for an explanation.
            //
            if value < BTSettingsInfo.Bounds.maxChargeMin {
                Task {
                    self.maxChargeNum = NSNumber(
                        value: BTSettingsInfo.Bounds.maxChargeMin
                    )
                }
            } else if value > 100 {
                Task {
                    self.maxChargeNum = NSNumber(value: 100)
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
        self.tabView.heightAnchor.constraint(equalToConstant: 384).isActive = true
        self.addInitialFocusView()
        self.configurePowerTabTextFields()
        self.cancelButton = self.view.subviews.compactMap {
            $0 as? NSButton
        }.first {
            $0.action == #selector(self.cancelButtonAction(_:))
        }
        self.addAboutButton()
        self.addPresetControl()
        self.addOptimizedChargingWarning()
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
                adapterSleep: self.adapterSleepSwitch.state == .off,
                magSafeSync: self.magSafeSyncSwitch.isEnabled ?
                    self.magSafeSyncSwitch.state == .on :
                    nil
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
                try await BTDaemonXPCClient.setSettings(settings: settings)
                self.view.window?.windowController?.close()
            } catch{
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
        self.updatePresetSelection()
    }
    
    private func setMaxCharge(value: Int) {
        self.maxChargeNum = NSNumber(value: value)
        self.updatePresetSelection()
    }

    private func addPresetControl() {
        guard let powerView = self.powerTab.view else {
            assertionFailure()
            return
        }

        let label = NSTextField(
            labelWithString: BTLocalization.Settings.preset
        )
        label.translatesAutoresizingMaskIntoConstraints = false

        let presetControl = NSSegmentedControl(
            labels: BTChargePreset.allCases.map(\.title),
            trackingMode: .selectOne,
            target: self,
            action: #selector(self.presetChanged(_:))
        )
        presetControl.translatesAutoresizingMaskIntoConstraints = false
        presetControl.segmentStyle = .rounded

        powerView.addSubview(label)
        powerView.addSubview(presetControl)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(
                equalTo: powerView.leadingAnchor,
                constant: 20
            ),
            label.centerYAnchor.constraint(equalTo: presetControl.centerYAnchor),

            presetControl.leadingAnchor.constraint(
                equalTo: label.trailingAnchor,
                constant: 8
            ),
            presetControl.topAnchor.constraint(
                equalTo: powerView.topAnchor,
                constant: 20
            ),
            presetControl.trailingAnchor.constraint(
                lessThanOrEqualTo: powerView.trailingAnchor,
                constant: -20
            ),
        ])

        self.presetControl = presetControl
        self.presetLabel = label
        self.updatePresetSelection()
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

    @objc private func presetChanged(_ sender: NSSegmentedControl) {
        guard
            let preset = BTChargePreset(rawValue: sender.selectedSegment)
        else {
            return
        }

        self.setMinCharge(value: preset.minCharge)
        self.setMaxCharge(value: preset.maxCharge)
    }

    private func updatePresetSelection() {
        let matchingPreset = BTChargePreset.matching(
            minCharge: Int(self.minChargeVal),
            maxCharge: Int(self.maxChargeVal)
        )

        self.presetControl?.selectedSegment = matchingPreset?.rawValue ?? -1
    }

    private func updateOptimizedChargingWarning() {
        self.optimizedChargingWarning?.isHidden =
            !IOPSPrivate.OptimizedBatteryChargingEngaged()
    }
    
    private func setAdapterSleep(value: Bool) {
        self.adapterSleepSwitch.state = value ? .off : .on
    }
    
    private func setMagSafeSync(value: Bool) {
        self.magSafeSyncSwitch.state = value ? .on : .off
    }
    
    private func initPowerState() async {
        do {
            let settings = try await BTActions.getSettings()
            self.currentSettings = settings
            self.updateOptimizedChargingWarning()
            
            let minChargeNum =
            settings[BTSettingsInfo.Keys.minCharge] as? NSNumber
            let maxChargeNum =
            settings[BTSettingsInfo.Keys.maxCharge] as? NSNumber
            let adapterSleepNum =
            settings[BTSettingsInfo.Keys.adapterSleep] as? NSNumber
            let magSafeSyncNum =
            settings[BTSettingsInfo.Keys.magSafeSync] as? NSNumber
            
            guard let minCharge = minChargeNum?.intValue,
                  let maxCharge = maxChargeNum?.intValue,
                  let adapterSleep = adapterSleepNum?.boolValue
            else {
                BTErrorHandler.errorHandler(error: BTError.commFailed)
                return
            }
            
            self.setMinCharge(value: minCharge)
            self.setMaxCharge(value: maxCharge)
            self.setAdapterSleep(value: adapterSleep)
            
            if let magSafeSync = magSafeSyncNum?.boolValue {
                self.magSafeSyncSwitch.isEnabled = true
                self.setMagSafeSync(value: magSafeSync)
            } else {
                self.magSafeSyncSwitch.isEnabled = false
            }
        } catch {
            BTErrorHandler.errorHandler(error: error)
        }
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
