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

class PreferencesViewController: NSViewController {
      
        @IBOutlet weak var hideCloverSettingsButton: NSButton!
        @IBOutlet weak var hidePackageDropButton: NSButton!
        @IBOutlet weak var hideOpenInBrowserButton: NSButton!
        @IBOutlet weak var openInBrowserUrlTextField: NSTextField!
        @IBOutlet weak var openInBrowserTitleTextField: NSTextField!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                if Defaults.shared.hideCloverSettings {
                        hideCloverSettingsButton.state = .on
                } else {
                        hideCloverSettingsButton.state = .off
                }
                if Defaults.shared.hidePackageDrop {
                        hidePackageDropButton.state = .on
                } else {
                        hidePackageDropButton.state = .off
                }
                if Defaults.shared.hideOpenInBrowser {
                        hideOpenInBrowserButton.state = .on
                        openInBrowserUrlTextField.isEnabled = false
                        openInBrowserTitleTextField.isEnabled = false
                } else {
                        hideOpenInBrowserButton.state = .off
                        openInBrowserUrlTextField.isEnabled = true
                        openInBrowserTitleTextField.isEnabled = true
                }
                openInBrowserUrlTextField.stringValue = Defaults.shared.openInBrowserUrl
                openInBrowserTitleTextField.stringValue = Defaults.shared.openInBrowserTitle
        }
 
        @IBAction func hideCloverSettingsButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hideCloverSettings = true
                } else {
                        Defaults.shared.hideCloverSettings = false
                }
        }
        
        @IBAction func hidePackageDropButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hidePackageDrop = true
                } else {
                        Defaults.shared.hidePackageDrop = false
                }
        }
        
        @IBAction func hideOpenInBrowserButtonPressed(_ sender: NSButton) {
                if sender.state == .on {
                        Defaults.shared.hideOpenInBrowser = true
                        openInBrowserUrlTextField.isEnabled = false
                        openInBrowserTitleTextField.isEnabled = false
                } else {
                        Defaults.shared.hideOpenInBrowser = false
                        openInBrowserUrlTextField.isEnabled = true
                        openInBrowserTitleTextField.isEnabled = true
                }
        }
        
        @IBAction func openInBrowserUrlTextFieldDidEndEditing(_ sender: NSTextField) {
                let string = openInBrowserUrlTextField.stringValue
                if URL.init(string: string) != nil {
                        Defaults.shared.openInBrowserUrl = string
                }
        }
        
        @IBAction func openInBrowserTitleTextFieldDidEndEditing(_ sender: NSTextField) {
                Defaults.shared.openInBrowserTitle = openInBrowserTitleTextField.stringValue
        }
        
}
