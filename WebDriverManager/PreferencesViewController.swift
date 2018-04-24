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

        @IBOutlet weak var hideBootArgumentsButton: NSButton!
        @IBOutlet weak var hideCloverSettingsButton: NSButton!
        @IBOutlet weak var showOpenInBrowserButton: NSButton!
        @IBOutlet weak var hideKernelExtensionsButton: NSButton!
        @IBOutlet weak var hidePackageInstaller: NSButton!
        @IBOutlet weak var toggleNotificationsPopupMenuButton: NSPopUpButton!
        @IBOutlet weak var checkNowButton: NSButton!
        @IBOutlet weak var updateCheckProgressIndicator: NSProgressIndicator!
        @IBOutlet weak var openInBrowserUrlTextField: NSTextField!
        @IBOutlet weak var openInBrowserTitleTextField: NSTextField!
        @IBOutlet weak var openInBrowserDescriptionLabel: NSTextField!
        
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
                if Defaults.shared.hideBootArguments {
                        hideBootArgumentsButton.state = .on
                } else {
                        hideBootArgumentsButton.state = .off
                }
                if Defaults.shared.hideCloverSettings {
                        hideCloverSettingsButton.state = .on
                } else {
                        hideCloverSettingsButton.state = .off
                }
                openInBrowserDescriptionLabel.wantsLayer = true
                if Defaults.shared.showOpenInBrowser {
                        showOpenInBrowserButton.state = .on
                        openInBrowserUrlTextField.isEnabled = true
                        openInBrowserTitleTextField.isEnabled = true
                        openInBrowserDescriptionLabel.layer?.opacity = enabled
                } else {
                        showOpenInBrowserButton.state = .off
                        openInBrowserUrlTextField.isEnabled = false
                        openInBrowserTitleTextField.isEnabled = false
                        openInBrowserDescriptionLabel.layer?.opacity = disabled
                }
                if Defaults.shared.hideKernelExtensions {
                        hideKernelExtensionsButton.state = .on
                } else {
                        hideKernelExtensionsButton.state = .off
                }
                openInBrowserUrlTextField.stringValue = Defaults.shared.openInBrowserUrl
                openInBrowserTitleTextField.stringValue = Defaults.shared.openInBrowserTitle
                
                if WebDriverNotifications.shared.checkInProgress {
                        disableUpdateCheckControls()
                } else {
                        enableUpdateCheckControls()
                }
                
                super.viewDidAppear()
        }
        
        
        @IBAction func hideBootArgumentsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hideBootArguments = true
                } else {
                        Defaults.shared.hideBootArguments = false
                }
        }
        
        @IBAction func hideCloverSettingsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hideCloverSettings = true
                } else {
                        Defaults.shared.hideCloverSettings = false
                }
        }

        @IBAction func showOpenInBrowserButtonPressed(_ sender: NSButton) {
                if sender.state == .off {
                        Defaults.shared.showOpenInBrowser = false
                        openInBrowserUrlTextField.isEnabled = false
                        openInBrowserTitleTextField.isEnabled = false
                        openInBrowserDescriptionLabel.isEnabled = false
                        openInBrowserDescriptionLabel.layer?.opacity = disabled
                } else {
                        Defaults.shared.showOpenInBrowser = true
                        openInBrowserUrlTextField.isEnabled = true
                        openInBrowserTitleTextField.isEnabled = true
                        openInBrowserDescriptionLabel.layer?.opacity = enabled
                }
        }
        
        @IBAction func hideKernelExtensionsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hideKernelExtensions = true
                } else {
                        Defaults.shared.hideKernelExtensions = false
                }
        }
        
        @IBAction func hidePackageInstallerButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hidePackageInstaller = true
                } else {
                        Defaults.shared.hidePackageInstaller = false
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
                Defaults.shared.openInBrowserTitle = openInBrowserTitleTextField.stringValue
        }
        
        @IBAction func checkNowButtonClicked(_ sender: NSButton) {
                if Defaults.shared.suppressUpdateAlerts != "" {
                        Defaults.shared.suppressUpdateAlerts = ""
                        os_log("Cancelling suppressUpdateAlerts", log: osLog, type: .info)
                }
                WebDriverNotifications.shared.beginUpdateCheck(overrideDefaults: true, userCheck: true)
        }
        
        @IBAction func notificationsPopupMenuItemEnabledClicked(_ sender: NSMenuItem) {
                if Defaults.shared.disableUpdateAlerts == true {
                        if Defaults.shared.suppressUpdateAlerts != "" {
                                Defaults.shared.suppressUpdateAlerts = ""
                                os_log("Cancelling suppressUpdateAlerts", log: osLog, type: .info)
                        }
                        Defaults.shared.disableUpdateAlerts = false
                        os_log("Automatic update notifications enabled", log: osLog, type: .info)
                        WebDriverNotifications.shared.beginUpdateCheck(overrideDefaults: true, userCheck: true)
                }
        }
        
        @IBAction func notificationsPopupMenuItemDisabledClicked(_ sender: NSMenuItem) {
                if Defaults.shared.disableUpdateAlerts == false {
                        Defaults.shared.disableUpdateAlerts = true
                        os_log("Automatic update notifications disabled", log: osLog, type: .info)
                        WebDriverNotifications.shared.updateCheckWorkItem?.cancel()
                }
        }
        
        
}
