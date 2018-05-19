/*
 * File: WebDriverNotifications.swift
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

class WebDriverUpdates: NSObject, NSUserNotificationCenterDelegate {
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Updates")
        
        static let shared = WebDriverUpdates()
        
        let updateCheckQueue = DispatchQueue(label: "updateCheck", attributes: .concurrent)
        var updateCheckWorkItem: DispatchWorkItem?
        var checkInProgress: Bool = false
        let updatesUrl = URL.init(string: "https://gfestage.nvidia.com/mac-update")
        let infoPlistUrl = URL.init(fileURLWithPath: "/Library/Extensions/GeForceWeb.kext/Contents/Info.plist")
        var checksum: String?
        var downloadUrl: String?
        var remoteVersion: String?
        
        var userWantsAlerts: Bool {
                return !Defaults.shared.disableUpdateAlerts
        }
        
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
        
        var build: String? {
                return sysctl(byName: "kern.osversion")
        }
        
        var localVersion: String? {
                os_log("Updates URL: %{public}@", log: osLog, type: .default, updatesUrl?.absoluteString ?? "nil")
                guard let info = NSDictionary.init(contentsOf: infoPlistUrl) else {
                        return nil
                }
                guard let infoString = info["CFBundleGetInfoString"] as? String else {
                        return nil
                }
                let components = infoString.split(separator: " ").map(String.init)
                guard components.count == 3 else {
                        return nil
                }
                os_log("Local version: %{public}@", log: osLog, type: .info, components[2])
                return components[2]
        }
        
        var updates: Array<AnyObject>? {
                if let url = updatesUrl {
                        guard let downloaded = NSDictionary.init(contentsOf: url) else {
                                return nil
                        }
                        guard let array = downloaded["updates"] as? NSArray else {
                                return nil
                        }
                        return array as Array<AnyObject>
                }
                return nil
        }
        
        func setup(notification: inout NSUserNotification, forVersion version: String) {
                notification.deliveryDate = NSDate(timeIntervalSinceNow: 1) as Date
                notification.title = NSLocalizedString("NVIDIA Web Driver", comment: "Update available notification title")
                notification.informativeText = String(format: "%@ %@", version, NSLocalizedString("available", comment: "Notification message: ... available"))
                notification.hasActionButton = true
                notification.setValue(1, forKey: "_showsButtons")
                notification.actionButtonTitle = NSLocalizedString("Don't Show Again", comment: "Notification action button")
                notification.identifier = version
                notification.soundName = NSUserNotificationDefaultSoundName
        }
        
        func setupNotAvailable(notification: inout NSUserNotification, message: String) {
                notification.deliveryDate = NSDate(timeIntervalSinceNow: 1) as Date
                notification.title = NSLocalizedString("Web Driver Manager", comment: "No update notification title")
                notification.informativeText = message
                notification.hasActionButton = false
                notification.setValue(0, forKey: "_showsButtons")
                notification.soundName = nil
        }
        
        func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
                return true
        }
        
        func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
                switch (notification.activationType) {
                case .actionButtonClicked:
                        if let versionToSuppress = notification.identifier {
                                os_log("Suppressing alerts for version: %{public}@", log: osLog, type: .default, versionToSuppress)
                                Defaults.shared.suppressUpdateAlerts = versionToSuppress
                        } else {
                                os_log("Notification identifier was nil, unable to suppress alerts", log: osLog, type: .default)
                        }
                default:
                        break;
                }
        }
        
        func beginUpdateCheck(overrideDefaults: Bool = false, userCheck: Bool = false) {
                updateCheckQueue.async {
                        self.updateCheckDidFinish(result: self.checkForUpdates(overrideDefaults: true, userCheck: userCheck))
                }
        }
        
        private func updateCheckDidFinish(result: Bool) {
                checkInProgress = false
                os_log("updateCheck returned %{public}@", log: osLog, type: .info, result.description)
                if userWantsAlerts {
                        updateCheckWorkItem = DispatchWorkItem {
                                self.updateCheckDidFinish(result: self.checkForUpdates())
                        }
                        updateCheckQueue.asyncAfter(deadline: DispatchTime.now() + updateCheckInterval, execute: updateCheckWorkItem!)
                }
                DispatchQueue.main.async {
                        for window in NSApplication.shared.windows {
                                if let id = window.identifier?.rawValue, id == "preferences" {
                                        if let controller = window.contentViewController as? PreferencesViewController {
                                                controller.enableUpdateCheckControls()
                                        }
                                }
                        }
                }
        }
        
        private func checkForUpdates(overrideDefaults: Bool = false, userCheck: Bool = false) -> Bool {
                DispatchQueue.main.async {
                        for window in NSApplication.shared.windows {
                                if let id = window.identifier?.rawValue, id == "preferences" {
                                        if let controller = window.contentViewController as? PreferencesViewController {
                                                controller.disableUpdateCheckControls()
                                        }
                                }
                        }
                }
                checkInProgress = true
                updateCheckWorkItem?.cancel()
                if userWantsAlerts == false && overrideDefaults == false {
                        os_log("Update notifications are disabled in user defaults", log: osLog, type: .info)
                        return false
                }
                if userWantsAlerts == false && overrideDefaults == true {
                        os_log("Overriding notifications disabled user default", log: osLog, type: .info)
                }
                guard updates != nil else {
                        os_log("Couldn't get updates data from NVIDIA", log: osLog, type: .default)
                        return false
                }
                for update in updates! {
                        guard let remoteBuild: String = update["OS"] as? String else {
                                continue
                        }
                        if remoteBuild != build {
                                continue
                        }
                        checksum = update["checksum"] as? String
                        downloadUrl = update["downloadURL"] as? String
                        remoteVersion = update["version"] as? String
                }
                guard remoteVersion != nil else {
                        os_log("Remote version is nil")
                        if userCheck {
                                var webDriverAlert = NSUserNotification()
                                if let build = build?.uppercased() {
                                        setupNotAvailable(notification: &webDriverAlert, message: "No update available for \(build)")
                                } else {
                                        setupNotAvailable(notification: &webDriverAlert, message: "No update available")
                                }
                                os_log("Scheduling 'no update available' notification, delivery date: %{public}@", log: osLog, type: .default, webDriverAlert.deliveryDate?.description ?? "unknown")
                                NSUserNotificationCenter.default.scheduleNotification(webDriverAlert)
                        }
                        return false
                }
                guard remoteVersion != localVersion else {
                        os_log("Remote version %{public}@ is already installed", log: osLog, type: .default, remoteVersion!)
                        if userCheck {
                                var webDriverAlert = NSUserNotification()
                                setupNotAvailable(notification: &webDriverAlert, message: "\(remoteVersion!) already installed")
                                os_log("Scheduling 'already installed' notification, delivery date: %{public}@", log: osLog, type: .default, webDriverAlert.deliveryDate?.description ?? "unknown")
                                NSUserNotificationCenter.default.scheduleNotification(webDriverAlert)
                        }
                        return false
                }
                guard remoteVersion != Defaults.shared.suppressUpdateAlerts else {
                        os_log("Alerts for %{public}@ have been suppressed in user defaults", log: osLog, type: .default, remoteVersion!)
                        return false
                }
                os_log("Remote version available: %{public}@", log: osLog, type: .default, remoteVersion!)
                var webDriverAlert = NSUserNotification()
                setup(notification: &webDriverAlert, forVersion: remoteVersion!)
                os_log("Scheduling update notification, delivery date: %{public}@", log: osLog, type: .default, webDriverAlert.deliveryDate?.description ?? "unknown")
                NSUserNotificationCenter.default.scheduleNotification(webDriverAlert)
                return true
        }
}

