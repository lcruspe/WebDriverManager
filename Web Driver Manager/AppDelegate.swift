/*
 * File: RegistryEntry.swift
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate  {
        
        @IBOutlet var statusMenu: NSMenu!
        @IBOutlet weak var defaultMenuItem: NSMenuItem!
        @IBOutlet weak var nvidiaMenuItem: NSMenuItem!
        @IBOutlet weak var driverStatusMenuItem: NSMenuItem!
        let nvidiaNvram = NvidiaNvram()
        let setNvramScript = NSAppleScript(source: "do shell script \"if nvram nvda_drv | grep nvda_drv; then nvram -d nvda_drv; else nvram nvda_drv=1%00; fi\" with administrator privileges")
        var scriptError: NSDictionary?
        let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        let accelerator = RegistryEntry.init(fromMatchingDictionary: IOServiceMatching("nvAccelerator"))
        var didDisplayRestartAlert = false
        
        func restartAlert() -> Bool {
                let alert = NSAlert()
                alert.messageText = "Settings will be applied after you restart."
                alert.informativeText = "Your bootloader may override the choice you make here."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                return alert.runModal() == .alertFirstButtonReturn
        }
        
        func applicationDidFinishLaunching(_ aNotification: Notification) {
                statusMenu.delegate = self
                if let button = statusItem.button {
                        button.image = NSImage(named:NSImage.Name("NVMenuIcon"))
                }
                statusItem.menu = statusMenu
                if let bundleId: String = accelerator.getStringValue(forProperty: "CFBundleIdentifier") {
                        if bundleId.uppercased().contains("WEB") {
                                driverStatusMenuItem.title = "\(bundleId)"
                                Log.log("NVIDIA Web Drivers are loaded")
                        } else {
                                driverStatusMenuItem.title = "Web drivers not loaded"
                                Log.log("NVIDIA Web Drivers are not loaded")
                        }
                } else {
                        driverStatusMenuItem.title = "Web drivers not loaded"
                        Log.log("NVIDIA Web Drivers are not loaded")
                }
                Log.log("Started")
        }
        
        func menuWillOpen(_ menu: NSMenu) {
                if nvidiaNvram.isSet {
                        nvidiaMenuItem.state = NSControl.StateValue.on
                        defaultMenuItem.state = NSControl.StateValue.off
                } else {
                        nvidiaMenuItem.state = NSControl.StateValue.off
                        defaultMenuItem.state = NSControl.StateValue.on
                }
        }
        
        @IBAction func exitImmediately(_ sender: NSMenuItem) {
                Log.log("Exiting")
                exit(0)
        }
        
        @IBAction func switchDriversClicked(_ sender: NSMenuItem) {
                Log.log("Setting nvda_drv nvram variable")
                setNvramScript?.executeAndReturnError(&scriptError)
                if !didDisplayRestartAlert {
                        let _ = restartAlert()
                        didDisplayRestartAlert = true
                }
        }
        
}
