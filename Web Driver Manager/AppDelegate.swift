/*
 * File: AppDelegate.swift
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

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
        
        @IBOutlet weak var statusMenu: NSMenu!
        @IBOutlet weak var driverStatusMenuItem: NSMenuItem!
        @IBOutlet weak var nvidiaMenuItem: NSMenuItem!
        @IBOutlet weak var defaultMenuItem: NSMenuItem!
        
        let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        let nvAccelerator = RegistryEntry.init(fromMatchingDictionary: IOServiceMatching("nvAccelerator"))
        var driverStatus: String?
        let nvram = Nvram()
        var nvramScriptError: NSDictionary?
        var nvramScript: NSAppleScript?
        var didDisplayRestartAlert = false
        
        override init() {
                super.init()
                if let bundleId: String = nvAccelerator.getStringValue(forProperty: "CFBundleIdentifier") {
                        if bundleId.uppercased().contains("WEB") {
                                driverStatus = "\(bundleId)"
                        } else {
                                driverStatus = "Web Drivers Not Loaded"
                        }
                } else {
                        driverStatus = "Web Drivers Not Loaded"
                }
                Log.log("Driver status: %{public}@", driverStatus ?? "Unavailable")
                if let nvramScriptUrl = Bundle.main.url(forResource: "nvram", withExtension: "applescript") {
                        nvramScript = NSAppleScript(contentsOf: nvramScriptUrl, error: &nvramScriptError)
                } else {
                        Log.log("Failed to get resource url for nvram script")
                }
        }
        
        func applicationDidFinishLaunching(_ aNotification: Notification) {
                if let button = statusItem.button {
                        button.image = NSImage(named:NSImage.Name("NVMenuIcon"))
                }
                statusItem.menu = statusMenu
                statusMenu.delegate = self
                if let showStatus: String = driverStatus {
                        driverStatusMenuItem.title = showStatus
                }
                Log.log("Started")
        }
        
        @IBAction func exitNow(_ sender: NSMenuItem) {
                Log.log("Exiting")
                exit(0)
        }
        
        func menuWillOpen(_ menu: NSMenu) {
                if nvram.useNvidia {
                        nvidiaMenuItem.state = NSControl.StateValue.on
                        defaultMenuItem.state = NSControl.StateValue.off
                } else {
                        nvidiaMenuItem.state = NSControl.StateValue.off
                        defaultMenuItem.state = NSControl.StateValue.on
                }
        }
        
        @IBAction func switchDriversClicked(_ sender: NSMenuItem) {
                Log.log("Setting nvda_drv nvram variable")
                let result: NSAppleEventDescriptor? = nvramScript?.executeAndReturnError(&nvramScriptError)
                if (result?.booleanValue)! {
                        if !didDisplayRestartAlert {
                                let _ = restartAlert()
                                didDisplayRestartAlert = true
                        }
                        return
                }
                NSSound.beep()
                Log.log("Failed to set nvda_drv NVRAM variable")
        }
        
        func restartAlert() -> Bool {
                let alert = NSAlert()
                alert.messageText = "Settings will be applied after you restart."
                alert.informativeText = "Your bootloader may override the choice you make here."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                return alert.runModal() == .alertFirstButtonReturn
        }
}
