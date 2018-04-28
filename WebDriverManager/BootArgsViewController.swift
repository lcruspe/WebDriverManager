/*
 * File: BootArgsViewController.swift
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

class BootArgsViewController: NSViewController {
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "BootArgsViewController")
        var bootArgs: String?
        
        @IBOutlet weak var bootArgsTextField: NSTextField!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                // Do view setup here.
        }
        
        override func viewDidAppear() {
                if let stringValue = Nvram.shared?.getStringValue(forProperty: "boot-args") {
                        bootArgs = stringValue
                } else {
                        bootArgs = ""
                }
                bootArgsTextField.stringValue = bootArgs ?? ""
        }
        
        @IBAction func ngfxButtonPressed(_ sender: NSButton) {
                var stringValue = bootArgsTextField.stringValue
                if stringValue.contains("ngfxcompat=1") {
                        stringValue = stringValue.replacingOccurrences(of: " ngfxcompat=1 ", with: " ")
                        stringValue = stringValue.replacingOccurrences(of: "ngfxcompat=1 ", with: "")
                        stringValue = stringValue.replacingOccurrences(of: " ngfxcompat=1", with: "")
                        stringValue = stringValue.replacingOccurrences(of: "ngfxcompat=1", with: "")
                        bootArgsTextField.stringValue = stringValue
                } else {
                        if bootArgsTextField.stringValue.isEmpty {
                                stringValue = "ngfxcompat=1"
                        } else {
                                stringValue = "ngfxcompat=1 \(stringValue)"
                        }
                        bootArgsTextField.stringValue = stringValue
                }
        }
        
        @IBAction func saveButtonPressed(_ sender: NSButton) {
                let arguments = bootArgsTextField.stringValue
                var script = "try\n"
                script += "\t" + "do shell script " + "\""
                script += "nvram boot-args=" + "\""
                script += " & quoted form of (\""
                script += arguments
                script += "\")"
                script += " with administrator privileges" + "\n"
                script += "on error errorNumber" + "\n"
                script += "\t" + "return false" + "\n"
                script += "end try" + "\n"
                script += "return true" + "\n"
                if debug {
                        print(script)
                }
                let appleScript = NSAppleScript(source: script)
                var error: NSDictionary?
                let eventDescriptor = appleScript?.executeAndReturnError(&error)
                if let bool = eventDescriptor?.booleanValue, bool == true {
                        os_log("Boot arguments were saved", log: osLog, type: .info)
                        view.window?.close()
                } else {
                        os_log("Failed to save boot arguments", log: osLog, type: .default)
                        NSApp.activate(ignoringOtherApps: true)
                        view.window?.makeKeyAndOrderFront(self)
                        NSSound.beep()
                }
        }
        
}
