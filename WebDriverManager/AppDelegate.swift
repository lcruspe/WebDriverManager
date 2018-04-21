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

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate {
        
        static let versionString = "1.13"
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "AppDelegate")
        
        @IBOutlet weak var statusMenu: NSMenu!
        @IBOutlet weak var checkNowMenuItem: NSMenuItem!
        @IBOutlet weak var toggleNotificationsMenuItem: NSMenuItem!
        
        let checkNowMenuItemTitle = NSLocalizedString("Check Now", comment: "Main menu: Check Now")
        let checkInProgressMenuItemTitle = NSLocalizedString("Check in progress...", comment: "Main menu: Check in progress")
        let restartAlertMessage = NSLocalizedString("Settings will be applied after you restart.", comment: "Restart alert: message")
        let restartAlertInformativeText = NSLocalizedString("Your bootloader may override the choice you make here.", comment: "Restart alert: informative text")
        let restartAlertButtonTitle = NSLocalizedString("Close", comment: "Restart alert: button title")
        
        var userWantsAlerts: Bool {
                return !Defaults.shared.disableUpdateAlerts
        }

        let fileManager = FileManager()
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
        
        func applicationDidFinishLaunching(_ aNotification: Notification) {
                os_log("Started")
                updateCheckQueue.async {
                        self.updateCheckDidFinish(result: self.beginUpdateCheck())
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
}
