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

class WebDriverAlert: NSUserNotification {
        
        override init() {
                super.init()
        }
        
        convenience init(remoteVersion: String) {
                self.init()
                deliveryDate = NSDate(timeIntervalSinceNow: 1) as Date
                title = "NVIDIA Web Driver"
                informativeText = "\(remoteVersion) is available."
                hasActionButton = true
                actionButtonTitle = "Don't Show Again"
                soundName = NSUserNotificationDefaultSoundName
        }
}

class WebDriverNotifications: NSObject, NSUserNotificationCenterDelegate {
        
        let nvidiaUpdatesUrl = "/Library/Extensions/GeForceWeb.kext/Contents/Info.plist"
        var checksum: String?
        var downloadUrl: String?
        var remoteVersion: String?
        
        var build: String? {
                get {
                        return sysctl(name: "kern.osversion")
                }
        }
        
        var localVersion: String? {
                get {
                        Log.log("Updates URL: %{public}@", nvidiaUpdatesUrl)
                        let infoPlistUrl = URL.init(fileURLWithPath: nvidiaUpdatesUrl)
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
                        Log.log("Local version: %{public}@", components[2])
                        return components[2]
                }
        }
        
        var updates: Array<AnyObject>? {
                get {
                        guard let updatesURL = URL.init(string: "https://gfestage.nvidia.com/mac-update") else {
                                return nil
                        }
                        guard let downloaded = NSDictionary.init(contentsOf: updatesURL) else {
                                return nil
                        }
                        guard let array = downloaded["updates"] as? NSArray else {
                                return nil
                        }
                        return array as Array<AnyObject>
                }
        }
        
        override init() {
                super.init()
        }
        
        func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
                return true
        }
        
        func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
                switch (notification.activationType) {
                case .actionButtonClicked:
                        let components = notification.informativeText?.split(separator: " ").map(String.init)
                        let versionToSuppress: String = components![0]
                        Log.log("Suppressing alerts for version: %{public}@", versionToSuppress)
                        Defaults.shared.suppressUpdateAlerts = versionToSuppress
                default:
                        break;
                }
        }
        
        func checkForUpdates() -> Bool {
                guard updates != nil else {
                        Log.log("Couldn't get updates data from NVIDIA")
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
                        Log.log("Remote version is nil")
                        return false
                }
                guard remoteVersion != localVersion else {
                        Log.log("Remote version %{public}@ is already installed", remoteVersion!)
                        return false
                }
                guard remoteVersion != Defaults.shared.suppressUpdateAlerts else {
                        Log.log("Alerts for %{public}@ have been suppressed in user defaults", remoteVersion!)
                        return false
                }
                Log.log("Remote version available: %{public}@", remoteVersion!)
                let webDriverAlert = WebDriverAlert(remoteVersion: remoteVersion!)
                Log.log("Scheduling update notification")
                NSUserNotificationCenter.default.scheduleNotification(webDriverAlert)
                return true
        }
}
