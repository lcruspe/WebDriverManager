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

#if DEBUG
let debug = true
#else
let debug = false
#endif

import Cocoa
import os.log

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
        
        static let versionString = "1.12"
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Default")
        var csrActiveConfig: UInt32 = 0xFFFF
        let unsignedKexts: UInt32 = 1 << 0
        let unrestrictedFilesystem: UInt32 = 1 << 1
        var fsAllowed: Bool = false
        var kextAllowed: Bool = false
        
        var packager = Packager()
        var packageUrl: URL? {
                didSet {
                        os_log("New URL for Packager: %{public}@", log: osLog, type: .default, packageUrl?.absoluteString ?? "nil")
                        if let url: URL = packageUrl {
                                showPackageDropMenuItem.isEnabled = false
                                packager.processPackage(atUrl: url)
                        }
                        packageUrl = nil
                }
        }
        
        var driverStatus = NSLocalizedString("Driver status unavailable", comment: "Main menu: Driver status unavailable")
        let driverNotInstalledMenuItemTitle = NSLocalizedString("Web driver not installed", comment: "Main menu: Web driver not installed")
        let driverNotInUseMenuItemTitle = NSLocalizedString("Web driver not in use", comment: "Main menu: Web driver not in use")
        let checkNowMenuItemTitle = NSLocalizedString("Check Now", comment: "Main menu: Check Now")
        let checkInProgressMenuItemTitle = NSLocalizedString("Check in progress...", comment: "Main menu: Check in progress")
        let disableNotificationsMenuItemTitle = NSLocalizedString("Disable Update Notifications", comment: "Main menu: Disable update notifications")
        let enableNotificationsMenuItemTitle = NSLocalizedString("Enable Update Notifications", comment: "Main menu: Enable update notifications")
        let notificationsEnabledMenuItemTitle = NSLocalizedString("Notifications: Enabled", comment: "Main menu: Notifications enabled")
        let notificationsDisabledMenuItemTitle = NSLocalizedString("Notifications: Disabled", comment: "Main menu: Notifications disabled")
        let restartAlertMessage = NSLocalizedString("Settings will be applied after you restart.", comment: "Restart alert: message")
        let restartAlertInformativeText = NSLocalizedString("Your bootloader may override the choice you make here.", comment: "Restart alert: informative text")
        let restartAlertButtonTitle = NSLocalizedString("Close", comment: "Restart alert: button title")
        let mountEFIItemTitle = NSLocalizedString("Mount EFI Partition", comment: "Main menu: Mount Clover/EFI")
        let unmountEFIItemTitle = NSLocalizedString("Unmount EFI Partition", comment: "Main menu: Unmount Clover/EFI")
        let openInBrowserMenuItemTitle = NSLocalizedString("Open % in Browser", comment: "Main menu: Open in browser replacing % with title from defaults")
        
        var storyboard: NSStoryboard?
        var aboutWindowController: NSWindowController?
        var preferencesWindowController: NSWindowController?
        var packageDropController: NSWindowController?
        
        @IBOutlet weak var statusMenu: NSMenu!
        @IBOutlet weak var driverStatusMenuItem: NSMenuItem!
        @IBOutlet weak var useNvidiaDriverMenuItem: NSMenuItem!
        @IBOutlet weak var useDefaultDriverMenuItem: NSMenuItem!
        @IBOutlet weak var checkNowMenuItem: NSMenuItem!
        @IBOutlet weak var notificationsStatusMenuItem: NSMenuItem!
        @IBOutlet weak var toggleNotificationsMenuItem: NSMenuItem!
        @IBOutlet weak var aboutMenuItem: NSMenuItem!
        @IBOutlet weak var quitMenuItem: NSMenuItem!
        @IBOutlet weak var cloverSubMenuItem: NSMenuItem!
        @IBOutlet weak var nvdaStartupMenuItem: NSMenuItem!
        @IBOutlet weak var nvidiaWebMenuItem: NSMenuItem!
        @IBOutlet weak var cloverPartitionMenuItem: NSMenuItem!
        @IBOutlet weak var showPackageDropMenuItem: NSMenuItem!
        @IBOutlet weak var preferencesMenuItem: NSMenuItem!
        @IBOutlet weak var openInBrowserSeparator: NSMenuItem!
        @IBOutlet weak var openInBrowserMenuItem: NSMenuItem!
        @IBOutlet weak var driverDoctorMenuItem: NSMenuItem!
        @IBOutlet weak var csrActiveConfigMenuItem: NSMenuItem!
        @IBOutlet weak var unstageGpuBundlesMenuItem: NSMenuItem!
        
        var userWantsAlerts: Bool {
                return !Defaults.shared.disableUpdateAlerts
        }
        let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        let nvAccelerator = RegistryEntry.init(fromMatchingDictionary: IOServiceMatching("nvAccelerator"))
        let nvram = Nvram()
        var appleScriptError: NSDictionary?
        var nvramScript: NSAppleScript?
        var unstageScript: NSAppleScript?
        var clearStagingScript: NSAppleScript?
        var touchScript: NSAppleScript?
        let fileManager = FileManager()
        let cloverSettings = NvidiaCloverSettings()
        let webDriverNotifications = WebDriverNotifications()
        let updateCheckQueue = DispatchQueue(label: "updateCheck", attributes: .concurrent)
        var updateCheckWorkItem: DispatchWorkItem?
        var updateCheckInterval: Double {
                get {
                        let hoursAfterCheck = Defaults.shared.hoursAfterCheck
                        var seconds: Double
                        if Set(1...48).contains(hoursAfterCheck) {
                                seconds = Double(hoursAfterCheck) * 3600.0
                        } else {
                                os_log("Invalid value for hoursAfterCheck, using 6 hours", log: osLog, type: .default)
                                seconds = 21600.0
                        }
                        os_log("Next check for updates after %{public}@ seconds", log: osLog, type: .info, seconds.description)
                        return seconds
                }
        }
        
        override init() {
                super.init()
                if let nvramScriptUrl = Bundle.main.url(forResource: "nvram", withExtension: "applescript") {
                        nvramScript = NSAppleScript(contentsOf: nvramScriptUrl, error: &appleScriptError)
                } else {
                        os_log("Failed to get resource URL for NVRAM script", log: osLog, type: .default)
                }
                if let unstageScriptUrl = Bundle.main.url(forResource: "unstage", withExtension: "applescript") {
                        unstageScript = NSAppleScript(contentsOf: unstageScriptUrl, error: &appleScriptError)
                } else {
                        os_log("Failed to get resource URL for unstage script", log: osLog, type: .default)
                }
                if let clearStagingScriptUrl = Bundle.main.url(forResource: "clearStaging", withExtension: "applescript") {
                        clearStagingScript = NSAppleScript(contentsOf: clearStagingScriptUrl, error: &appleScriptError)
                } else {
                        os_log("Failed to get resource URL for clear staging script", log: osLog, type: .default)
                }
                if let touchScriptUrl = Bundle.main.url(forResource: "touch", withExtension: "applescript") {
                        touchScript = NSAppleScript(contentsOf: touchScriptUrl, error: &appleScriptError)
                } else {
                        os_log("Failed to get resource URL for touch script", log: osLog, type: .default)
                }
                let _ = csr_get_active_config(&csrActiveConfig)
                kextAllowed = !(csr_check(unsignedKexts) != 0)
                fsAllowed = !(csr_check(unrestrictedFilesystem) != 0)
        }
        
        func applicationDidFinishLaunching(_ aNotification: Notification) {
                if let button = statusItem.button {
                        button.image = NSImage(named:NSImage.Name("NVMenuIcon"))
                }
                statusItem.isVisible = true
                statusItem.behavior = NSStatusItem.Behavior.terminationOnRemoval
                statusItem.menu = statusMenu
                statusMenu.delegate = self
                NSUserNotificationCenter.default.delegate = webDriverNotifications
                updateCheckQueue.async {
                        self.updateCheckDidFinish(result: self.beginUpdateCheck())
                }
                storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
                aboutWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "aboutWindowController")) as? NSWindowController
                packageDropController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "packagerWindowController")) as? NSWindowController
                preferencesWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "preferencesWindowController")) as? NSWindowController
                os_log("Started", log: osLog, type: .default)
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
                if let useNvidia = nvram?.useNvidia {
                        useNvidiaDriverMenuItem.isEnabled = true
                        useDefaultDriverMenuItem.isEnabled = true
                        if useNvidia == true {
                                useNvidiaDriverMenuItem.state = .on
                                useDefaultDriverMenuItem.state = .off
                        } else {
                                useNvidiaDriverMenuItem.state = .off
                                useDefaultDriverMenuItem.state = .on
                        }
                } else {
                        useNvidiaDriverMenuItem.isEnabled = false
                        useDefaultDriverMenuItem.isEnabled = false
                        
                }
                if Defaults.shared.disableUpdateAlerts {
                        notificationsStatusMenuItem.title = notificationsDisabledMenuItemTitle
                        toggleNotificationsMenuItem?.title = enableNotificationsMenuItemTitle
                } else {
                        notificationsStatusMenuItem.title = notificationsEnabledMenuItemTitle
                        toggleNotificationsMenuItem?.title = disableNotificationsMenuItemTitle
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
                if Defaults.shared.hidePackageDrop {
                        showPackageDropMenuItem.isHidden = true
                } else {
                        showPackageDropMenuItem.isHidden = false
                }
                if Defaults.shared.hideOpenInBrowser {
                        openInBrowserSeparator.isHidden = true
                        openInBrowserMenuItem.isHidden = true
                } else {
                        openInBrowserMenuItem.title = openInBrowserMenuItemTitle.replacingOccurrences(of: "%", with: Defaults.shared.openInBrowserTitle)
                        openInBrowserSeparator.isHidden = false
                        openInBrowserMenuItem.isHidden = false
                }
                if Defaults.shared.hideDriverDoctor {
                        driverDoctorMenuItem.isHidden = true
                } else {
                        driverDoctorMenuItem.isHidden = false
                }
                csrActiveConfigMenuItem.title = "CSR Active Config: \(String(format: "0x%X", csrActiveConfig))"
                if fsAllowed {
                        unstageGpuBundlesMenuItem.isEnabled = true
                } else {
                        unstageGpuBundlesMenuItem.isEnabled = false
                }
        }
        
        @IBAction func changeDriverMenuItemClicked(_ sender: NSMenuItem) {
                if sender.state == .on {
                        return
                }
                os_log("Setting nvda_drv NVRAM variable", log: osLog, type: .default)
                let result: NSAppleEventDescriptor? = nvramScript?.executeAndReturnError(&appleScriptError)
                if (result?.booleanValue)! {
                        if Defaults.shared.showRestartAlert {
                                makeAndShowRestartAlert()
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
        
        @IBAction func cloverPartitionMenuItemClicked(_ sender: Any) {
                if cloverPartitionMenuItem.title == mountEFIItemTitle {
                        cloverSettings?.mountEfi()
                } else {
                        cloverSettings?.unmountEfi()
                }
        }
        
        func cancelSuppressedVersion() {
                if Defaults.shared.suppressUpdateAlerts != "" {
                        Defaults.shared.suppressUpdateAlerts = ""
                        os_log("Cancelling suppressUpdateAlerts", log: osLog, type: .default)
                }
        }
        
        @IBAction func checkNowMenuItemClicked(_ sender: NSMenuItem) {
                cancelSuppressedVersion()
                updateCheckQueue.async {
                        self.updateCheckDidFinish(result: self.beginUpdateCheck(overrideDefaults: true, userCheck: true))
                }
        }
        
        @IBAction func toggleNotificationsMenuItemClicked(_ sender: NSMenuItem) {
                if Defaults.shared.disableUpdateAlerts {
                        cancelSuppressedVersion()
                        Defaults.shared.disableUpdateAlerts = false
                        os_log("Automatic update notifications enabled", log: osLog, type: .default)
                        updateCheckQueue.async {
                                self.updateCheckDidFinish(result: self.beginUpdateCheck(overrideDefaults: true))
                        }
                } else {
                        Defaults.shared.disableUpdateAlerts = true
                        os_log("Automatic update notifications disabled", log: osLog, type: .default)
                }
        }
        
        func beginUpdateCheck(overrideDefaults: Bool = false, userCheck: Bool = false) -> Bool {
                updateCheckWorkItem?.cancel()
                checkNowMenuItem.isEnabled = false
                toggleNotificationsMenuItem.isEnabled = false
                checkNowMenuItem.title = checkInProgressMenuItemTitle
                if userWantsAlerts || overrideDefaults {
                        if !userWantsAlerts && overrideDefaults {
                                os_log("Overriding notifications disabled user default", log: osLog, type: .info)
                        }
                        return webDriverNotifications.checkForUpdates(userCheck: userCheck)
                } else {
                        os_log("Update notifications are disabled in user defaults", log: osLog, type: .info)
                        return false
                }
        }
        
        func updateCheckDidFinish(result: Bool) {
                os_log("updateCheck returned %{public}@", log: osLog, type: .info, result.description)
                checkNowMenuItem.isEnabled = true
                toggleNotificationsMenuItem.isEnabled = true
                checkNowMenuItem.title = checkNowMenuItemTitle
                if userWantsAlerts {
                        updateCheckWorkItem = DispatchWorkItem {
                                self.updateCheckDidFinish(result: self.beginUpdateCheck())
                        }
                        updateCheckQueue.asyncAfter(deadline: DispatchTime.now() + updateCheckInterval, execute: updateCheckWorkItem!)
                }
        }
        
        func makeAndShowRestartAlert() {
                let alert = NSAlert()
                alert.messageText = restartAlertMessage
                alert.informativeText = restartAlertInformativeText
                alert.alertStyle = .informational
                alert.addButton(withTitle: restartAlertButtonTitle)
                alert.showsSuppressionButton = true
                alert.runModal()
                if (alert.suppressionButton?.state == .on) {
                        Defaults.shared.showRestartAlert = false
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
        
        @IBAction func packageDropMenuItemClicked(_ sender: NSMenuItem) {
                if let window = packageDropController?.window {
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
                let result: NSAppleEventDescriptor? = unstageScript?.executeAndReturnError(&appleScriptError)
                if (result?.booleanValue)! {
                        os_log("Unstage script finished", log: osLog, type: .default)
                        return
                }
                NSSound.beep()
                os_log("Error running unstage script", log: osLog, type: .default)
        }
        
        @IBAction func clearStagingMenuItemClicked(_ sender: NSMenuItem) {
                let result: NSAppleEventDescriptor? = clearStagingScript?.executeAndReturnError(&appleScriptError)
                if (result?.booleanValue)! {
                        os_log("Clear staging script finished", log: osLog, type: .default)
                        return
                }
                NSSound.beep()
                os_log("Error running clear staging script", log: osLog, type: .default)
        }
        
        @IBAction func touchExtensionsMenuItemClicked(_ sender: NSMenuItem) {
                let result: NSAppleEventDescriptor? = touchScript?.executeAndReturnError(&appleScriptError)
                if (result?.booleanValue)! {
                        os_log("Touch script finished", log: osLog, type: .default)
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
                os_log("Quit menu item clicked, exiting", log: osLog, type: .info)
                exit(0)
        }        
}
