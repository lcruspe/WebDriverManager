/*
 * File: StatusMenuController.swift
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

class StatusMenuController: NSObject, NSMenuDelegate {

        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "StatusMenuController")
        let cloverSettings = NVCloverSettings()
        let fileManager = FileManager()
        var csrActiveConfig: UInt32 = 0xFFFF
        let unsignedKexts: UInt32 = 1 << 0
        let unrestrictedFilesystem: UInt32 = 1 << 1
        var fsAllowed: Bool = false
        var kextAllowed: Bool = false
        var scriptError: NSDictionary?

        let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        var storyboard: NSStoryboard?
        var aboutWindowController: NSWindowController?
        var preferencesWindowController: NSWindowController?
        var packagerWindowController: NSWindowController?
        var editBootArgsController: NSWindowController?
        
        override init() {
                super.init()
                let _ = csr_get_active_config(&csrActiveConfig)
                kextAllowed = !(csr_check(unsignedKexts) != 0)
                fsAllowed = !(csr_check(unrestrictedFilesystem) != 0)
        }

        let nvAccelerator = RegistryEntry.init(fromMatchingDictionary: IOServiceMatching("nvAccelerator"))
        
        var driverStatus = NSLocalizedString("Driver status unavailable", comment: "Main menu: Driver status unavailable")
        let driverNotInstalledMenuItemTitle = NSLocalizedString("Web driver not installed", comment: "Main menu: Web driver not installed")
        let driverNotInUseMenuItemTitle = NSLocalizedString("Web driver not in use", comment: "Main menu: Web driver not in use")
        let mountEFIItemTitle = NSLocalizedString("Mount EFI Partition", comment: "Main menu: Mount Clover/EFI")
        let unmountEFIItemTitle = NSLocalizedString("Unmount EFI Partition", comment: "Main menu: Unmount Clover/EFI")
        let openInBrowserMenuItemTitle = NSLocalizedString("Open % in Browser", comment: "Main menu: Open in browser replacing % with title from defaults")
        let restartAlertMessage = NSLocalizedString("Settings will be applied after you restart.", comment: "Restart alert: message")
        let restartAlertInformativeText = NSLocalizedString("Your bootloader may override the choice you make here.", comment: "Restart alert: informative text")
        let restartAlertButtonTitle = NSLocalizedString("Close", comment: "Restart alert: button title")
        let scriptErrorAlertMessage = NSLocalizedString("Running a script caused an error", comment: "Script error alert message")
        let scriptErrorInformativeText = NSLocalizedString("If you keep seeing this message you can report it here: https://github.com/vulgo/WebDriverManager", comment: "Script error informative script")
        let restartAfterScriptAlertMessage = NSLocalizedString("Caches will be rebuilt", comment: "Reboot after script alert message")
        let restartAfterScriptInformativeText = NSLocalizedString("Restart to update the boot volume and apply changes.", comment: "Reboot after script informative text")

        @IBOutlet weak var statusMenu: NSMenu!
        @IBOutlet weak var driverStatusMenuItem: NSMenuItem!
        @IBOutlet weak var useNvidiaDriverMenuItem: NSMenuItem!
        @IBOutlet weak var useDefaultDriverMenuItem: NSMenuItem!
        @IBOutlet weak var aboutMenuItem: NSMenuItem!
        @IBOutlet weak var quitMenuItem: NSMenuItem!
        @IBOutlet weak var bootArgumentsMenuItem: NSMenuItem!
        @IBOutlet weak var cloverSubMenuItem: NSMenuItem!
        @IBOutlet weak var nvdaStartupMenuItem: NSMenuItem!
        @IBOutlet weak var nvidiaWebMenuItem: NSMenuItem!
        @IBOutlet weak var cloverPartitionMenuItem: NSMenuItem!
        @IBOutlet weak var packageInstallerMenuItem: NSMenuItem!
        @IBOutlet weak var preferencesMenuItem: NSMenuItem!
        @IBOutlet weak var openInBrowserMenuItem: NSMenuItem!
        @IBOutlet weak var kernelExtensionsMenuItem: NSMenuItem!
        @IBOutlet weak var csrActiveConfigMenuItem: NSMenuItem!
        @IBOutlet weak var unstageGpuBundlesMenuItem: NSMenuItem!
        @IBOutlet weak var clearStagingMenuItem: NSMenuItem!
        
        override func awakeFromNib() {
                if let button = statusItem.button {
                        button.image = NSImage(named:NSImage.Name("NVMenuIcon"))
                }
                statusItem.isVisible = true
                statusItem.behavior = NSStatusItem.Behavior.terminationOnRemoval
                statusItem.menu = statusMenu
                statusMenu.delegate = self
                storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
                aboutWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "aboutWindowController")) as? NSWindowController
                packagerWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "packagerWindowController")) as? NSWindowController
                preferencesWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "preferencesWindowController")) as? NSWindowController
                editBootArgsController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "editBootArgsWindowController")) as? NSWindowController
        }
        
        func menuWillOpen(_ menu: NSMenu) {
                if fileManager.fileExists(atPath: "/Library/Extensions/NVDAStartupWeb.kext") {
                        if let bundleId: String = nvAccelerator.getStringValue(forProperty: "CFBundleIdentifier"), bundleId.uppercased().contains("WEB") {
                                driverStatus = "\(bundleId)"
                        } else {
                                driverStatus = driverNotInUseMenuItemTitle
                        }
                        useNvidiaDriverMenuItem.isEnabled = true
                        useDefaultDriverMenuItem.isEnabled = true
                        driverStatusMenuItem.title = driverStatus
                } else {
                        useNvidiaDriverMenuItem.isEnabled = false
                        useDefaultDriverMenuItem.isEnabled = false
                        driverStatusMenuItem.title = driverNotInstalledMenuItemTitle
                }
                if Nvram.shared!.useNvidia {
                        useNvidiaDriverMenuItem.state = .on
                        useDefaultDriverMenuItem.state = .off
                } else {
                        useNvidiaDriverMenuItem.state = .off
                        useDefaultDriverMenuItem.state = .on
                }
                if Defaults.shared.bootArgumentsIsVisible {
                        bootArgumentsMenuItem.isHidden = false
                } else {
                        bootArgumentsMenuItem.isHidden = true
                }
                if cloverSettings != nil && Defaults.shared.cloverSettingsIsVisible {
                        cloverSubMenuItem.isHidden = false
                        if cloverSettings!.nvidiaWebIsEnabled {
                                nvidiaWebMenuItem.state = .on
                        } else {
                                nvidiaWebMenuItem.state = .off
                        }
                        if cloverSettings!.nvdaStartupPatchIsEnabled {
                                nvdaStartupMenuItem.state = .on
                        } else {
                                nvdaStartupMenuItem.state = .off
                        }
                } else {
                        cloverSubMenuItem.isHidden = true
                }
                if let url: URL = cloverSettings?.lastVolumeUrl {
                        if fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: FileManager.VolumeEnumerationOptions())?.contains(url) ?? false {
                                cloverPartitionMenuItem.title = unmountEFIItemTitle
                        } else {
                                cloverPartitionMenuItem.title = mountEFIItemTitle
                        }
                }
                if Defaults.shared.openInBrowserIsVisible {
                        openInBrowserMenuItem.title = openInBrowserMenuItemTitle.replacingOccurrences(of: "%", with: Defaults.shared.openInBrowserTitle)
                        openInBrowserMenuItem.isHidden = false
                } else {

                        openInBrowserMenuItem.isHidden = true
                }
                if Defaults.shared.kernelExtensionsIsVisible {
                        kernelExtensionsMenuItem.isHidden = false
                } else {
                        kernelExtensionsMenuItem.isHidden = true
                }
                if Defaults.shared.packageInstallerIsVisible {
                        packageInstallerMenuItem.isHidden = false
                } else {
                        packageInstallerMenuItem.isHidden = true
                }
                csrActiveConfigMenuItem.title = "CSR Active Config: \(String(format: "0x%X", csrActiveConfig))"
                if fsAllowed {
                        unstageGpuBundlesMenuItem.isHidden = false
                        clearStagingMenuItem.isHidden = true
                } else {
                        unstageGpuBundlesMenuItem.isHidden = true
                        clearStagingMenuItem.isHidden = false
                }
        }
        
        func showScriptErrorAlert() {
                let alert = NSAlert()
                alert.messageText = scriptErrorAlertMessage
                alert.informativeText = scriptErrorInformativeText
                alert.runModal()
        }
        
        func showRestartAfterScriptAlert() {
                let alert = NSAlert()
                alert.messageText = restartAfterScriptAlertMessage
                alert.informativeText = restartAfterScriptInformativeText
                alert.runModal()
        }
        
        /* Menu actions */
        
        @IBAction func changeDriverMenuItemClicked(_ sender: NSMenuItem) {
                if sender.state == .on {
                        return
                }
                os_log("Setting nvda_drv nvram variable", log: osLog, type: .info)
                let result = Scripts.shared.nvram?.executeAndReturnError(&scriptError)
                if Scripts.shared.boolValue(result) {
                        if Defaults.shared.showRestartAlert {
                                let alert = NSAlert()
                                alert.messageText = restartAlertMessage
                                alert.informativeText = restartAlertInformativeText
                                alert.addButton(withTitle: restartAlertButtonTitle)
                                alert.showsSuppressionButton = true
                                alert.runModal()
                                if (alert.suppressionButton?.state == .on) {
                                        Defaults.shared.showRestartAlert = false
                                }
                        }
                        return
                }
                NSSound.beep()
                os_log("Failed to set nvda_drv NVRAM variable", log: osLog, type: .default)
        }
        
        @IBAction func nvdaStartupWebMenuItemClicked(_ sender: NSMenuItem) {
                if cloverSettings == nil {
                        return
                }
                if sender.state == .on {
                        cloverSettings!.nvdaStartupPatchIsEnabled = false
                } else {
                        cloverSettings!.nvdaStartupPatchIsEnabled = true
                }
        }
        
        @IBAction func nvidiaWebMenuItemClicked(_ sender: NSMenuItem) {
                if cloverSettings == nil {
                        return
                }
                if sender.state == .on {
                        cloverSettings!.nvidiaWebIsEnabled = false
                } else {
                        cloverSettings!.nvidiaWebIsEnabled = true
                }
        }
        
        @IBAction func bootArgumentsMenuItemClicked(_ sender: NSMenuItem) {
                if let window = editBootArgsController?.window {
                        if !window.isVisible {
                                window.center()
                        }
                        window.level = .floating
                        NSApp.activate(ignoringOtherApps: true)
                        window.makeKeyAndOrderFront(self)
                }
        }
        
        @IBAction func cloverPartitionMenuItemClicked(_ sender: NSMenuItem) {
                if cloverPartitionMenuItem.title == mountEFIItemTitle {
                        cloverSettings?.mountEfi()
                } else {
                        cloverSettings?.unmountEfi()
                }
        }

        @IBAction func aboutMenuItemClicked(_ sender: NSMenuItem) {
                if let window = aboutWindowController?.window {
                        if !window.isVisible {
                                window.center()
                        }
                        window.isMovableByWindowBackground = true
                        window.level = .floating
                        NSApp.activate(ignoringOtherApps: true)
                        window.makeKeyAndOrderFront(self)
                        window.level = .normal
                }
        }
        
        @IBAction func showPackageInstallerMenuItemClicked(_ sender: Any) {
                if let window = packagerWindowController?.window {
                        window.appearance = NSAppearance.init(named: NSAppearance.Name.vibrantLight)
                        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        window.standardWindowButton(.zoomButton)?.isHidden = true
                        window.isMovableByWindowBackground = true
                        if !window.isVisible {
                                let originX = (NSScreen.main?.visibleFrame.origin.x)! + (NSScreen.main?.visibleFrame.size.width)! - window.frame.size.width - 48.0
                                let originY = (NSScreen.main?.visibleFrame.origin.y)! + (NSScreen.main?.visibleFrame.size.height)! - window.frame.size.height - 48.0
                                window.setFrameOrigin(NSPoint(x: originX, y: originY))
                        }
                        window.level = .floating
                        NSApp.activate(ignoringOtherApps: true)
                        window.makeKeyAndOrderFront(self)
                }
        }
        
        @IBAction func openInBrowserMenuItemClicked(_ sender: Any) {
                if let url = URL.init(string: Defaults.shared.openInBrowserUrl) {
                        NSWorkspace.shared.open(url)
                } else {
                        os_log("Failed to create URL for opening in browser", log: osLog, type: .default)
                }
        }
        
        @IBAction func unstageGpuBundlesMenuItemClicked(_ sender: NSMenuItem) {
                let result = Scripts.shared.unstage?.executeAndReturnError(&scriptError)
                if Scripts.shared.boolValue(result) {
                        os_log("Unstage script finished", log: osLog, type: .info)
                        showRestartAfterScriptAlert()
                        return
                }
                NSSound.beep()
                os_log("Error running unstage script", log: osLog, type: .default)
                showScriptErrorAlert()
        }
        
        @IBAction func clearStagingMenuItemClicked(_ sender: NSMenuItem) {
                let result = Scripts.shared.clearStaging?.executeAndReturnError(&scriptError)
                if Scripts.shared.boolValue(result) {
                        os_log("Clear staging script finished", log: osLog, type: .info)
                        showRestartAfterScriptAlert()
                        return
                }
                NSSound.beep()
                os_log("Error running clear staging script", log: osLog, type: .default)
                showScriptErrorAlert()
        }
        
        @IBAction func touchExtensionsMenuItemClicked(_ sender: NSMenuItem) {
                let result = Scripts.shared.touch?.executeAndReturnError(&scriptError)
                if Scripts.shared.boolValue(result) {
                        os_log("Touch script finished", log: osLog, type: .info)
                        showRestartAfterScriptAlert()
                        return
                }
                NSSound.beep()
                os_log("Error running touch script", log: osLog, type: .default)
                showScriptErrorAlert()
        }
        
        @IBAction func preferencesMenuItemClicked(_ sender: Any) {
                if let window = preferencesWindowController?.window {
                        if !window.isVisible {
                                window.center()
                        }
                        window.level = .floating
                        NSApp.activate(ignoringOtherApps: true)
                        window.makeKeyAndOrderFront(self)
                        window.level = .normal
                }
        }
        
        @IBAction func quitMenuItemClicked(_ sender: NSMenuItem) {
                os_log("Quit menu item clicked", log: osLog, type: .default)
                DispatchQueue.main.async {
                        NSApp.terminate(nil)
                }
        }        
}
