/*
 * File: AboutViewController.swift
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

class AboutViewController: NSViewController {
        
        let versionString: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unavailable"
        
        @IBOutlet weak var versionTextField: NSTextField!
        let sourceUrl = URL(string: "https://github.com/vulgo/WebDriverManager")
        let licenseUrl = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
        
        override func viewDidLoad() {
                super.viewDidLoad()
                versionTextField.stringValue = String(format: "%@ %@", NSLocalizedString("Version", comment: ""), versionString)
                view.wantsLayer = true
                view.layer?.backgroundColor = CGColor.white
        }
        
        @IBAction func sourceButtonPressed(_ sender: Any) {
                NSWorkspace.shared.open(sourceUrl!)
        }
        
        @IBAction func licenseButtonPressed(_ sender: Any) {
                NSWorkspace.shared.open(licenseUrl!)
        }
}
