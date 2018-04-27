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
        
        var packager = Packager()
        var scripts = Scripts()
        let cloverSettings = NvidiaCloverSettings()
        let fileManager = FileManager()
        
        var packageUrl: URL? {
                didSet {
                        os_log("PackagerViewController: new url %{public}@", log: osLog, type: .info, packageUrl?.absoluteString ?? "nil")
                        if let url: URL = packageUrl {
                                showPackageInstallerMenuItem.isEnabled = false
                                packager.processPackage(atUrl: url)
                        }
                        packageUrl = nil
                }
        }

        var csrActiveConfig: UInt32 = 0xFFFF
        let unsignedKexts: UInt32 = 1 << 0
        let unrestrictedFilesystem: UInt32 = 1 << 1
        var fsAllowed: Bool = false
        var kextAllowed: Bool = false

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
        @IBOutlet weak var showPackageInstallerMenuItem: NSMenuItem!
        @IBOutlet weak var preferencesMenuItem: NSMenuItem!
        @IBOutlet weak var openInBrowserMenuItem: NSMenuItem!
        @IBOutlet weak var driverDoctorMenuItem: NSMenuItem!
        @IBOutlet weak var csrActiveConfigMenuItem: NSMenuItem!
        @IBOutlet weak var unstageGpuBundlesMenuItem: NSMenuItem!
        
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
                if !Defaults.shared.hideBootArguments {
                        bootArgumentsMenuItem.isHidden = false
                } else {
                        bootArgumentsMenuItem.isHidden = true
                }
                if cloverSettings != nil && !Defaults.shared.hideCloverSettings {
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
                if Defaults.shared.showOpenInBrowser {
                        openInBrowserMenuItem.title = openInBrowserMenuItemTitle.replacingOccurrences(of: "%", with: Defaults.shared.openInBrowserTitle)

                        openInBrowserMenuItem.isHidden = false
                } else {

                        openInBrowserMenuItem.isHidden = true
                }
                if Defaults.shared.hideKernelExtensions {
                        driverDoctorMenuItem.isHidden = true
                } else {
                        driverDoctorMenuItem.isHidden = false
                }
                if Defaults.shared.hidePackageInstaller {
                        showPackageInstallerMenuItem.isHidden = true
                } else {
                        showPackageInstallerMenuItem.isHidden = false
                }
                csrActiveConfigMenuItem.title = "CSR Active Config: \(String(format: "0x%X", csrActiveConfig))"
                if fsAllowed {
                        unstageGpuBundlesMenuItem.isEnabled = true
                } else {
                        unstageGpuBundlesMenuItem.isEnabled = false
                }
        }
        
        /* Menu actions */
        
        @IBAction func changeDriverMenuItemClicked(_ sender: NSMenuItem) {
                if sender.state == .on {
                        return
                }
                os_log("Setting nvda_drv nvram variable", log: osLog, type: .info)
                let result = scripts.nvram?.executeAndReturnError(&scripts.error)
                if scripts.boolValue(result) {
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
        
        @IBAction func bootArgumentsMenuItemClicked(_ sender: Any) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = editBootArgsController?.window {
                        if !window.isVisible {
                                window.center()
                        }
                        window.level = .floating
                        window.makeKeyAndOrderFront(self)
                }
        }
        
        @IBAction func cloverPartitionMenuItemClicked(_ sender: Any) {
                if cloverPartitionMenuItem.title == mountEFIItemTitle {
                        cloverSettings?.mountEfi()
                } else {
                        cloverSettings?.unmountEfi()
                }
        }

        @IBAction func aboutMenuItemClicked(_ sender: NSMenuItem) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = aboutWindowController?.window {
                        if !window.isVisible {
                                window.center()
                        }
                        window.isMovableByWindowBackground = true
                        window.level = .floating
                        window.makeKeyAndOrderFront(self)
                        window.level = .normal
                }
        }
        
        @IBAction func showPackageInstallerMenuItemClicked(_ sender: NSMenuItem) {
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
                        window.makeKeyAndOrderFront(self)
                }
        }
        
        @IBAction func openInBrowserMenuItemClicked(_ sender: NSMenuItem) {
                if let url = URL.init(string: Defaults.shared.openInBrowserUrl) {
                        NSWorkspace.shared.open(url)
                } else {
                        os_log("Failed to create URL for opening in browser", log: osLog, type: .default)
                }
        }
        
        @IBAction func unstageGpuBundlesMenuItemClicked(_ sender: NSMenuItem) {
                let result = scripts.unstage?.executeAndReturnError(&scripts.error)
                if scripts.boolValue(result) {
                        os_log("Unstage script finished", log: osLog, type: .info)
                        return
                }
                NSSound.beep()
                os_log("Error running unstage script", log: osLog, type: .default)
        }
        
        @IBAction func clearStagingMenuItemClicked(_ sender: NSMenuItem) {
                let result = scripts.clearStaging?.executeAndReturnError(&scripts.error)
                if scripts.boolValue(result) {
                        os_log("Clear staging script finished", log: osLog, type: .info)
                        return
                }
                NSSound.beep()
                os_log("Error running clear staging script", log: osLog, type: .default)
        }
        
        @IBAction func touchExtensionsMenuItemClicked(_ sender: NSMenuItem) {
                let result = scripts.touch?.executeAndReturnError(&scripts.error)
                if scripts.boolValue(result) {
                        os_log("Touch script finished", log: osLog, type: .info)
                        return
                }
                NSSound.beep()
                os_log("Error running touch script", log: osLog, type: .default)
        }
        
        @IBAction func preferencesMenuItemClicked(_ sender: NSMenuItem) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = preferencesWindowController?.window {
                        if !window.isVisible {
                                window.center()
                        }
                        window.level = .floating
                        window.makeKeyAndOrderFront(self)
                        window.level = .normal
                }
        }
        
        @IBAction func quitMenuItemClicked(_ sender: NSMenuItem) {
                os_log("Quit menu item clicked, exiting", log: osLog, type: .default)
                exit(0)
        }        
}