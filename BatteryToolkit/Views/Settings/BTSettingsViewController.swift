//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTSettingsViewController: NSViewController {
    private static let contentSize = NSSize(width: 520, height: 353)

    private enum ChargePreset: Int, CaseIterable {
        case everyday
        case desk
        case travel

        var title: String {
            switch self {
            case .everyday:
                return BTLocalization.Settings.Presets.everyday
            case .desk:
                return BTLocalization.Settings.Presets.desk
            case .travel:
                return BTLocalization.Settings.Presets.travel
            }
        }

        var minCharge: Int {
            switch self {
            case .everyday:
                return 70
            case .desk:
                return 50
            case .travel:
                return 80
            }
        }

        var maxCharge: Int {
            switch self {
            case .everyday, .desk:
                return 80
            case .travel:
                return 90
            }
        }
    }

    private let autostartSetting = "autostart"
    
    private var currentSettings: [String: NSObject & Sendable]? = nil
    private var presetLabel: NSTextField? = nil
    private var presetControl: NSSegmentedControl? = nil
    private weak var cancelButton: NSButton? = nil
    private var optimizedChargingWarning: NSTextField? = nil
    private var isPowerFooterVisible = true
    
    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var userTab: NSTabViewItem!
    @IBOutlet private var powerTab: NSTabViewItem!
    
    @IBOutlet private var autostartSwitch: NSSwitch!
    private var statusItemDisplayModePopUpButton: NSPopUpButton!
    
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
        self.configurePowerTabTextFields()
        self.cancelButton = self.view.subviews.compactMap {
            $0 as? NSButton
        }.first {
            $0.action == #selector(self.cancelButtonAction(_:))
        }
        self.configureUserTab()
        self.addPresetControl()
        self.addOptimizedChargingWarning()
    }
    
    @IBAction private func cancelButtonAction(_: NSButton) {
        self.view.window?.windowController?.close()
    }
    
    @IBAction private func doneButtonAction(_: NSButton) {
        let autostart = (self.autostartSwitch.state == .on)
        let success = autostart ?
        BTLoginItem.enable() :
        BTLoginItem.disable()
        
        if success {
            UserDefaults.standard.setValue(
                autostart,
                forKey: self.autostartSetting
            )
        } else {
            BTErrorHandler.errorHandler(
                error: BTError.unknown,
                window: self.view.window
            )
        }

        self.saveStatusItemDisplayMode()
        
        let settings: [String: NSObject & Sendable] = [
            BTSettingsInfo.Keys.minCharge: self.minChargeNum,
            BTSettingsInfo.Keys.maxCharge: self.maxChargeNum,
            BTSettingsInfo.Keys.adapterSleep: NSNumber(
                value: self.adapterSleepSwitch.state == .off
            ),
            BTSettingsInfo.Keys.magSafeSync: NSNumber(
                value: self.magSafeSyncSwitch.state == .on
            ),
        ]
        //
        // Submit the settings to the daemon only when they changed.
        //
        guard !(settings as NSDictionary).isEqual(to: self.currentSettings)
        else {
            os_log("Power settings have not changed, ignoring")
            //
            // If the previous operations failed, we displayed an error prompt
            // and must not close the window.
            //
            if success {
                self.view.window?.windowController?.close()
            }
            
            return
        }
        
        Task {
            do {
                try await BTDaemonXPCClient.setSettings(settings: settings)
                //
                // If the previous operations failed, we already displayed an
                // error prompt and must not close the window.
                //
                guard success else {
                    return
                }
                
                self.view.window?.windowController?.close()
            } catch{
                BTErrorHandler.errorHandler(
                    error: error,
                    window: self.view.window
                )
            }
        }
    }

    @objc private func uninstallButtonAction(_: NSButton) {
        Task {
            await BTAppPrompts.promptRemoveDaemonAndAppData(
                window: self.view.window
            )
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.initUserState()
        
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
    
    func selectUserTab() {
        self.tabView.selectTabViewItem(self.userTab)
        self.setPowerFooterVisible(false)
    }
    
    func selectPowerTab() {
        self.tabView.selectTabViewItem(self.powerTab)
        self.setPowerFooterVisible(true)
    }

    private func configureUserTab() {
        guard let userView = self.userTab.view else {
            assertionFailure()
            return
        }

        NSLayoutConstraint.deactivate(userView.constraints)
        for subview in userView.subviews {
            subview.removeFromSuperview()
        }

        let settingsUserView = BTSettingsUserView(
            uninstallTarget: self,
            uninstallAction: #selector(self.uninstallButtonAction(_:))
        )
        userView.addSubview(settingsUserView)

        NSLayoutConstraint.activate([
            settingsUserView.topAnchor.constraint(
                equalTo: userView.topAnchor
            ),
            settingsUserView.leadingAnchor.constraint(
                equalTo: userView.leadingAnchor
            ),
            settingsUserView.trailingAnchor.constraint(
                equalTo: userView.trailingAnchor
            ),
            settingsUserView.bottomAnchor.constraint(
                equalTo: userView.bottomAnchor
            ),
        ])

        self.autostartSwitch = settingsUserView.autostartSwitch
        self.statusItemDisplayModePopUpButton =
            settingsUserView.statusItemDisplayModePopUpButton
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
    
    private func setMinCharge(value: Int) {
        self.minChargeNum = NSNumber(value: value)
        self.updatePresetSelection()
    }
    
    private func setMaxCharge(value: Int) {
        self.maxChargeNum = NSNumber(value: value)
        self.updatePresetSelection()
    }

    private func addPresetControl() {
        let label = NSTextField(
            labelWithString: BTLocalization.Settings.preset
        )
        label.translatesAutoresizingMaskIntoConstraints = false

        let presetControl = NSSegmentedControl(
            labels: ChargePreset.allCases.map(\.title),
            trackingMode: .selectOne,
            target: self,
            action: #selector(self.presetChanged(_:))
        )
        presetControl.translatesAutoresizingMaskIntoConstraints = false
        presetControl.segmentStyle = .rounded

        self.view.addSubview(label)
        self.view.addSubview(presetControl)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: 20
            ),
            label.centerYAnchor.constraint(equalTo: presetControl.centerYAnchor),

            presetControl.leadingAnchor.constraint(
                equalTo: label.trailingAnchor,
                constant: 8
            ),
            presetControl.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor,
                constant: -18
            ),
        ])
        if let cancelButton {
            presetControl.trailingAnchor.constraint(
                lessThanOrEqualTo: cancelButton.leadingAnchor,
                constant: -12
            ).isActive = true
        } else {
            presetControl.trailingAnchor.constraint(
                lessThanOrEqualTo: self.view.trailingAnchor,
                constant: -20
            ).isActive = true
        }

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

        let bottomAnchor = self.presetControl?.topAnchor ??
            self.view.bottomAnchor
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
                equalTo: bottomAnchor,
                constant: -6
            ),
        ])

        self.optimizedChargingWarning = warning
    }

    @objc private func presetChanged(_ sender: NSSegmentedControl) {
        guard
            let preset = ChargePreset(rawValue: sender.selectedSegment)
        else {
            return
        }

        self.setMinCharge(value: preset.minCharge)
        self.setMaxCharge(value: preset.maxCharge)
    }

    private func updatePresetSelection() {
        let matchingPreset = ChargePreset.allCases.first { preset in
            preset.minCharge == Int(self.minChargeVal) &&
                preset.maxCharge == Int(self.maxChargeVal)
        }

        self.presetControl?.selectedSegment = matchingPreset?.rawValue ?? -1
    }

    private func updateOptimizedChargingWarning() {
        self.optimizedChargingWarning?.isHidden =
            !self.isPowerFooterVisible ||
                !IOPSPrivate.OptimizedBatteryChargingEngaged()
    }

    private func setPowerFooterVisible(_ isVisible: Bool) {
        self.isPowerFooterVisible = isVisible
        self.presetLabel?.isHidden = !isVisible
        self.presetControl?.isHidden = !isVisible
        self.updateOptimizedChargingWarning()
    }
    
    private func setAdapterSleep(value: Bool) {
        self.adapterSleepSwitch.state = value ? .off : .on
    }
    
    private func setMagSafeSync(value: Bool) {
        self.magSafeSyncSwitch.state = value ? .on : .off
    }
    
    private func initUserState() {
        let autostart = UserDefaults.standard.bool(
            forKey: self.autostartSetting
        )
        self.autostartSwitch.state = autostart ? .on : .off
        self.statusItemDisplayModePopUpButton.selectItem(
            withTag: BTStatusItemDisplayMode.current.rawValue
        )
    }

    private func saveStatusItemDisplayMode() {
        let selectedTag = self.statusItemDisplayModePopUpButton.selectedTag()
        guard
            selectedTag >= 0,
            let displayMode = BTStatusItemDisplayMode(
                rawValue: selectedTag
            )
        else {
            return
        }

        BTStatusItemDisplayMode.current = displayMode
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

private extension NSView {
    var allTextFields: [NSTextField] {
        self.subviews.flatMap { subview in
            ([subview as? NSTextField].compactMap { $0 }) +
                subview.allTextFields
        }
    }
}
