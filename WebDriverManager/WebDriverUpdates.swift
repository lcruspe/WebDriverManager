/*
 * File: WebDriverUpdates.swift
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
        
        var localBuild: String? {
                return sysctl(byName: "kern.osversion")
        }
        
        var localVersion: String? {
                
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
        
        var localCompatibleOS: String? {
                
                let infoPlistUrl = URL.init(fileURLWithPath: "/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist")
                guard let info = NSDictionary.init(contentsOf: infoPlistUrl) else {
                        return nil
                }
                guard let ioKitPersonalities = info["IOKitPersonalities"] as? NSDictionary else {
                        return nil
                }
                guard let nvdaStartup = ioKitPersonalities["NVDAStartup"] as? NSDictionary else {
                        return nil
                }
                guard let compatibleBuild = nvdaStartup["NVDARequiredOS"] as? String else {
                        return nil
                }
                
                return compatibleBuild
        }
        
        private struct cache {
                static var updates: Array<AnyObject>?
                static var time: Date?
                static let timeout: Double = 1800.0
        }
        
        var updates: Array<AnyObject>? {
                
                if cache.updates != nil, cache.time != nil, cache.time! < cache.time!.addingTimeInterval(cache.timeout)  {
                        
                        return cache.updates
                        
                } else {
                        
                        let buffer: Array<AnyObject>? = sync()

                        if buffer != nil {
                                cache.updates = buffer
                                cache.time = Date()
                        }
                        
                        return cache.updates
                }
                
        }
        
        var cacheTime: Date? {
                return cache.time
        }
        
        @discardableResult func refresh() -> Bool {
                
                let buffer: Array<AnyObject>? = sync()
                
                if buffer != nil {
                        cache.updates = buffer
                        cache.time = Date()
                        return true
                } else {
                        return false
                }
        }
        
        private func sync() -> Array<AnyObject>? {
                
                os_log("Downloading data from NVIDIA", log: osLog, type: .default)
                
                if let url = updatesUrl {
                        
                        guard let downloaded = NSDictionary.init(contentsOf: url) else {
                                return nil
                        }
                        
                        guard let array = downloaded["updates"] as? NSArray else {
                                return nil
                        }
                        
                        var updates = array as Array<AnyObject>
                        
                        updates = updates.filter {
                                (update) in
                                guard let dictionary = update as? [String: Any] else {
                                        return false
                                }
                                guard let os = dictionary["OS"] as? String else {
                                        return false
                                }
                                if let majorVersion = Int(String(os[..<os.index(os.startIndex, offsetBy: 2)])), majorVersion > 16 {
                                        return true
                                } else {
                                        return false
                                }
                        }
                        
                        return updates
                }
                
                return nil
        }
        
        override init() {
                super.init()
                os_log("Updates URL: %{public}@", log: osLog, type: .default, updatesUrl?.absoluteString ?? "nil")
        }
        
        func newUserNotification(forVersion version: String) -> NSUserNotification {
                
                let n = NSUserNotification()
                let updateAction = NSUserNotificationAction(identifier: "update", title: NSLocalizedString("Open updater...", comment: ""))
                let suppressAction = NSUserNotificationAction(identifier: "suppress", title: NSLocalizedString("Suppress alerts for \(version)", comment: ""))
                let additionalActions: [NSUserNotificationAction] = [updateAction, suppressAction]
                
                n.deliveryTimeZone = TimeZone.current
                n.deliveryDate = NSDate(timeIntervalSinceNow: 1) as Date
                n.title = NSLocalizedString("NVIDIA Web Driver", comment: "")
                n.informativeText = String(format: "%@ %@", version, NSLocalizedString("available", comment: ""))
                n.hasActionButton = true
                n.otherButtonTitle = NSLocalizedString("Close", comment: "")
                n.additionalActions = additionalActions
                n.setValue(1, forKey: "_showsButtons")
                n.setValue(1, forKey: "_alwaysShowAlternateActionMenu")
                n.userInfo = ["version": version]
                n.soundName = NSUserNotificationDefaultSoundName
                
                return n
        }
        
        func newUserNotification(withMessage message: String) -> NSUserNotification {
                
                let n = NSUserNotification()
                
                n.deliveryTimeZone = TimeZone.current
                n.deliveryDate = NSDate(timeIntervalSinceNow: 1) as Date
                n.title = NSLocalizedString("Web Driver Manager", comment: "")
                n.informativeText = message
                n.hasActionButton = false
                n.setValue(0, forKey: "_showsButtons")
                n.soundName = nil
                
                return n
                
        }
        
        func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
                return true
        }
        
        func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
                switch (notification.activationType) {
                case .additionalActionClicked:
                        if notification.additionalActivationAction?.identifier == "update" {
                                if let statusMenuController = (NSApplication.shared.delegate as? AppDelegate)?.statusMenu.delegate as? StatusMenuController {
                                        statusMenuController.updaterMenuItemClicked(self)
                                }
                        }
                        if notification.additionalActivationAction?.identifier == "suppress" {
                                if let versionToSuppress = notification.userInfo?["version"] as? String {
                                        os_log("Suppressing alerts for version: %{public}@", log: osLog, type: .default, versionToSuppress)
                                        Defaults.shared.suppressUpdateAlerts = versionToSuppress
                                } else {
                                        os_log("Failed to read version to suppress from user notification user info", log: osLog, type: .default)
                                }
                        }
                default:
                        break;
                }
        }
        
        func beginUpdateCheck(overrideDefaults: Bool = false, userCheck: Bool = false) {
                updateCheckQueue.async {
                        self.updateCheckDidFinish(result: self.checkForUpdates(overrideDefaults: overrideDefaults, userCheck: userCheck))
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
                
                switch (userWantsAlerts, overrideDefaults) {
                        
                case (false, false):
                        os_log("Update notifications are disabled in user defaults", log: osLog, type: .info)
                        
                        return false
                        
                case (false, true):
                        os_log("Overriding 'notifications disabled' user default", log: osLog, type: .info)
                        
                        fallthrough
                        
                default:
                        if userCheck {
                                refresh()
                        }
                        
                        if updates == nil {
                                os_log("No updates data is available", log: osLog, type: .default)
                                
                                return false
                        }
                        
                }
                
                for update in updates! {
                        
                        guard let remoteBuild: String = update["OS"] as? String else {
                                continue
                        }
                        
                        if remoteBuild != localBuild {
                                continue
                        }
                        
                        checksum = update["checksum"] as? String
                        downloadUrl = update["downloadURL"] as? String
                        remoteVersion = update["version"] as? String
                        
                }
                
                if remoteVersion == nil {
                        /* No update available */
                        os_log("Remote version is nil")
                        
                        if userCheck {
                                /* Notify user if this check occurred due to user interaction */
                                var noUpdateNotification: NSUserNotification
                                if let build = localBuild?.uppercased() {
                                        noUpdateNotification = newUserNotification(withMessage: "No update available for \(build)")
                                } else {
                                        noUpdateNotification = newUserNotification(withMessage: "No update available")
                                }
                                os_log("Scheduling 'no update available' notification, delivery date: %{public}@", log: osLog, type: .default, noUpdateNotification.deliveryDate?.description ?? "unknown")
                                
                                NSUserNotificationCenter.default.scheduleNotification(noUpdateNotification)
                                
                        }
                        
                        return false
                }
                
                if remoteVersion == localVersion {
                        /* Compatible remote version is already installed */
                        os_log("Remote version %{public}@ is already installed", log: osLog, type: .default, remoteVersion!)
                        
                        if userCheck {
                                /* Notify user if this check occurred due to user interaction */
                                let alreadyInstalledNotification = newUserNotification(withMessage: "\(remoteVersion!) already installed")
                                os_log("Scheduling 'already installed' notification, delivery date: %{public}@", log: osLog, type: .default, alreadyInstalledNotification.deliveryDate?.description ?? "unknown")
                                
                                NSUserNotificationCenter.default.scheduleNotification(alreadyInstalledNotification)
                                
                        }
                        
                        return false
                }
                
                guard remoteVersion != Defaults.shared.suppressUpdateAlerts else {
                        /* Update is available, user requested no notifications for this version */
                        os_log("Alerts for %{public}@ have been suppressed in user defaults", log: osLog, type: .default, remoteVersion!)
                        
                        return false
                }
                
                /* Update is available, notify user */
                os_log("Remote version available: %{public}@", log: osLog, type: .default, remoteVersion!)
                let updateNotification = newUserNotification(forVersion: remoteVersion!)
                os_log("Scheduling update notification, delivery date: %{public}@", log: osLog, type: .default, updateNotification.deliveryDate?.description ?? "unknown")
                
                NSUserNotificationCenter.default.scheduleNotification(updateNotification)
                
                return true
        }
}

