/*
 * File: PreferencesViewController.swift
 *
 * WebDriverManager © vulgo 2018
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Cocoa
import os.log

class PreferencesViewController: NSViewController {
                
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Preferences")

        @IBOutlet weak var stageGPUBundlesButton: NSButton!
        @IBOutlet weak var bootArgumentsVisibilityButton: NSButton!
        @IBOutlet weak var cloverSettingsVisibilityButton: NSButton!
        @IBOutlet weak var openInBrowserVisibilityButton: NSButton!
        @IBOutlet weak var kernelExtensionsVisibilityButton: NSButton!
        @IBOutlet weak var packageInstallerVisibilityButton: NSButton!
        @IBOutlet weak var toggleNotificationsPopupMenuButton: NSPopUpButton!
        @IBOutlet weak var checkNowButton: NSButton!
        @IBOutlet weak var updateCheckProgressIndicator: NSProgressIndicator!
        @IBOutlet weak var openInBrowserUrlTextField: NSTextField!
        @IBOutlet weak var openInBrowserDescriptionTextField: NSTextField!
        
        let disabled: Float = 0.3
        let enabled: Float = 1.0
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        func disableUpdateCheckControls() {
                toggleNotificationsPopupMenuButton.isEnabled = false
                checkNowButton.isEnabled = false
                updateCheckProgressIndicator.startAnimation(self)
        }
        
        func enableUpdateCheckControls() {
                toggleNotificationsPopupMenuButton.isEnabled = true
                checkNowButton.isEnabled = true
                updateCheckProgressIndicator.stopAnimation(self)
        }
        
        override func viewDidAppear() {
                
                func setup(menuItemButton: NSButton, value: Bool) {
                        if value {
                                menuItemButton.state = .on
                        } else {
                                menuItemButton.state = .off
                        }
                }
                
                setup(menuItemButton: stageGPUBundlesButton, value: Defaults.shared.stageGPUBundles)
                
                setup(menuItemButton: bootArgumentsVisibilityButton, value: Defaults.shared.bootArgumentsIsVisible)
                setup(menuItemButton: cloverSettingsVisibilityButton, value: Defaults.shared.cloverSettingsIsVisible)
                setup(menuItemButton: packageInstallerVisibilityButton, value: Defaults.shared.packageInstallerIsVisible)
                setup(menuItemButton: openInBrowserVisibilityButton, value: Defaults.shared.openInBrowserIsVisible)
                setup(menuItemButton: kernelExtensionsVisibilityButton, value: Defaults.shared.kernelExtensionsIsVisible)

                if Defaults.shared.disableUpdateAlerts {
                        toggleNotificationsPopupMenuButton.selectItem(at: 1)
                } else {
                        toggleNotificationsPopupMenuButton.selectItem(at: 0)
                }
                
                openInBrowserUrlTextField.stringValue = Defaults.shared.openInBrowserUrl
                openInBrowserDescriptionTextField.stringValue = Defaults.shared.openInBrowserTitle
                
                if WebDriverUpdates.shared.checkInProgress {
                        disableUpdateCheckControls()
                } else {
                        enableUpdateCheckControls()
                }
                
                super.viewDidAppear()
        }
        
        @IBAction func stageGPUBundlesButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.stageGPUBundles = true
                } else {
                        Defaults.shared.stageGPUBundles = false
                }
        }
        
        @IBAction func hideBootArgumentsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.bootArgumentsIsVisible = true
                } else {
                        Defaults.shared.bootArgumentsIsVisible = false
                }
        }
        
        @IBAction func hideCloverSettingsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.cloverSettingsIsVisible = true
                } else {
                        Defaults.shared.cloverSettingsIsVisible = false
                }
        }

        @IBAction func showOpenInBrowserButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.openInBrowserIsVisible = true
                        openInBrowserUrlTextField.isEnabled = true
                } else {
                        Defaults.shared.openInBrowserIsVisible = false
                }
        }
        
        @IBAction func hideKernelExtensionsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.kernelExtensionsIsVisible = true
                } else {
                        Defaults.shared.kernelExtensionsIsVisible = false
                }
        }
        
        @IBAction func hidePackageInstallerButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.packageInstallerIsVisible = true
                } else {
                        Defaults.shared.packageInstallerIsVisible = false
                }
        }

        @IBAction func openInBrowserUrlTextFieldDidEndEditing(_ sender: NSTextField) {
                var string = openInBrowserUrlTextField.stringValue
                if let url = URL.init(string: string) {
                        if let scheme = url.scheme {
                                if scheme == "http" || scheme == "https" {
                                        Defaults.shared.openInBrowserUrl = string
                                        return
                                }
                        } else {
                                string = "https://\(string)"
                                Defaults.shared.openInBrowserUrl = string
                                return
                        }
                }
                openInBrowserUrlTextField.stringValue = Defaults.shared.openInBrowserUrl
        }
        
        @IBAction func openInBrowserTitleTextFieldDidEndEditing(_ sender: NSTextField) {
                Defaults.shared.openInBrowserTitle = openInBrowserDescriptionTextField.stringValue
        }
        
        @IBAction func checkNowButtonClicked(_ sender: NSButton) {
                if Defaults.shared.suppressUpdateAlerts != "" {
                        Defaults.shared.suppressUpdateAlerts = ""
                        os_log("Cancelling suppressUpdateAlerts", log: osLog, type: .info)
                }
                WebDriverUpdates.shared.beginUpdateCheck(overrideDefaults: true, userCheck: true)
        }
        
        @IBAction func notificationsPopupMenuItemEnabledClicked(_ sender: NSMenuItem) {
                if Defaults.shared.disableUpdateAlerts == true {
                        if Defaults.shared.suppressUpdateAlerts != "" {
                                Defaults.shared.suppressUpdateAlerts = ""
                                os_log("Cancelling suppressUpdateAlerts", log: osLog, type: .info)
                        }
                        Defaults.shared.disableUpdateAlerts = false
                        os_log("Automatic update notifications enabled", log: osLog, type: .info)
                        WebDriverUpdates.shared.beginUpdateCheck(overrideDefaults: true, userCheck: true)
                }
        }
        
        @IBAction func notificationsPopupMenuItemDisabledClicked(_ sender: NSMenuItem) {
                if Defaults.shared.disableUpdateAlerts == false {
                        Defaults.shared.disableUpdateAlerts = true
                        os_log("Automatic update notifications disabled", log: osLog, type: .info)
                        WebDriverUpdates.shared.updateCheckWorkItem?.cancel()
                }
        }
        
        
}
