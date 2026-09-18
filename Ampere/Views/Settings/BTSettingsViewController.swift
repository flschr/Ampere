//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTSettingsViewController: NSViewController {
    static let contentSize = NSSize(width: 520, height: 308)
    static let legacyContentSize = NSSize(width: 520, height: 350)
    static let footerHeight: CGFloat = 69

    var currentSettings: [String: NSObject & Sendable]? = nil
    var capabilities = BTPowerCapabilities.legacy
    private weak var cancelButton: NSButton? = nil
    var optimizedChargingWarning: NSTextField? = nil
    let initialFocusView = BTSettingsInitialFocusView()
    var contentHeightConstraint: NSLayoutConstraint?
    var tabHeightConstraint: NSLayoutConstraint?
    var legacySectionTopConstraint: NSLayoutConstraint?
    var managedSectionTopConstraint: NSLayoutConstraint?

    @IBOutlet var tabView: NSTabView!
    @IBOutlet var powerTab: NSTabViewItem!

    @IBOutlet var minChargeTextField: NSTextField!
    @IBOutlet var minChargeSlider: NSSlider!

    @IBOutlet var maxChargeTextField: NSTextField!
    @IBOutlet var maxChargeSlider: NSSlider!
    @IBOutlet var chargingSleepDescription: NSTextField!

    let lowPowerThresholdControls = BTLowPowerThresholdControls()

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
        self.contentHeightConstraint = self.view.heightAnchor.constraint(
            equalToConstant: Self.contentSize.height
        )
        self.contentHeightConstraint?.isActive = true
        self.tabView.selectTabViewItem(self.powerTab)
        self.tabHeightConstraint = self.tabView.heightAnchor.constraint(
            equalToConstant: Self.contentSize.height - Self.footerHeight
        )
        self.tabHeightConstraint?.isActive = true
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

    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.initialFirstResponder = self.initialFocusView
        Task {
            await self.initPowerState()
            self.view.window?.center()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(self.initialFocusView)
    }

    func setMinCharge(value: Int) {
        self.minChargeNum = NSNumber(value: value)
    }

    func setMaxCharge(value: Int) {
        self.maxChargeNum = NSNumber(value: value)
    }
}
