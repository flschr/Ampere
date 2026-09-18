//
// Copyright (C) 2026 René Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

@MainActor
extension BTSettingsViewController {
    func initPowerState() async {
        do {
            let settings = try await BTActions.getSettings()
            let parsedSettings = try BTBatterySettings(payload: settings)
            self.currentSettings = settings
            self.capabilities = parsedSettings.capabilities
            self.configureCapabilities()
            self.updateOptimizedChargingWarning()
            self.setMinCharge(value: parsedSettings.minCharge)
            self.setMaxCharge(value: parsedSettings.maxCharge)
            self.lowPowerThresholdControls.threshold = parsedSettings.lowPowerModeThreshold
        } catch {
            BTErrorHandler.errorHandler(error: error)
        }
    }

    private func configureCapabilities() {
        let customRange = self.capabilities.customChargeRange
        self.minChargeTextField.isEnabled = customRange
        self.minChargeSlider.isEnabled = customRange
        self.maxChargeSlider.minValue = Double(self.capabilities.minimumMaxCharge)
        self.maxChargeSlider.numberOfTickMarks =
            (100 - self.capabilities.minimumMaxCharge) /
            self.capabilities.maxChargeStep + 1
        self.maxChargeSlider.allowsTickMarkValuesOnly =
            self.capabilities.maxChargeStep > 1

        let managed = self.capabilities.chargeControlMode != .legacySMC
        self.chargingSleepDescription.isHidden = managed
        self.legacySectionTopConstraint?.isActive = false
        self.managedSectionTopConstraint?.isActive = false
        if managed {
            self.managedSectionTopConstraint?.isActive = true
        } else {
            self.legacySectionTopConstraint?.isActive = true
        }

        let size = managed ? Self.contentSize : Self.legacyContentSize
        self.contentHeightConstraint?.constant = size.height
        self.tabHeightConstraint?.constant = size.height - Self.footerHeight
        (self.view.window?.windowController as? BTSettingsWindowController)?
            .setSettingsContentSize(size)
    }

    private func updateOptimizedChargingWarning() {
        self.optimizedChargingWarning?.isHidden =
            self.capabilities.chargeControlMode == .systemManaged ||
            !IOPSPrivate.OptimizedBatteryChargingEngaged()
    }
}
