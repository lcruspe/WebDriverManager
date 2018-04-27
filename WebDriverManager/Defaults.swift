/*
 * File: Defaults.swift
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

import Foundation

class Defaults {
        
        static let shared = Defaults()
        let userDefaults = UserDefaults.standard
        
        enum WebDriverManager {
                case initialized
                case showRestartAlert
                case suppressVersion
                case disableUpdateAlerts
                case hideBootArguments
                case hideCloverSettings
                case showOpenInBrowser
                case hideKernelExtensions
                case hidePackageInstaller
                case openInBrowserUrl
                case openInBrowserTitle
                case hoursAfterCheck
                var key: String {
                        switch self {
                        case .initialized:
                                return "initialized"
                        case .showRestartAlert:
                                return "showRestartAlert"
                        case .suppressVersion:
                                return "suppressUpdateAlerts"
                        case .disableUpdateAlerts:
                                return "disabledUpdateAlerts"
                        case .hideBootArguments:
                                return "hideBootArguments"
                        case .hideCloverSettings:
                                return "hideCloverSettings"
                        case .showOpenInBrowser:
                                return "showOpenInBrowser"
                        case .hideKernelExtensions:
                                return "hideKernelExtensions"
                        case .hidePackageInstaller:
                                return "hidePackageInstaller"
                        case .openInBrowserUrl:
                                return "openInBrowserUrl"
                        case .openInBrowserTitle:
                                return "openInBrowserTitle"
                        case .hoursAfterCheck:
                                return "hoursAfterCheck"
                        }
                }
        }
        
        private init() {
                if !debug {
                        registerFactoryDefaults()
                } else {
                        reset()
                }
        }
        
        var initialized: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.initialized.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.initialized.key)
                }
        }
        
        var showRestartAlert: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.showRestartAlert.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.showRestartAlert.key)
                }
        }
        
        var suppressUpdateAlerts: String {
                get {
                        return userDefaults.string(forKey: WebDriverManager.suppressVersion.key)!
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.suppressVersion.key)
                }
        }
        
        var disableUpdateAlerts: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.disableUpdateAlerts.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.disableUpdateAlerts.key)
                }
        }
        
        var hideBootArguments: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.hideBootArguments.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.hideBootArguments.key)
                }
        }
        
        var hideCloverSettings: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.hideCloverSettings.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.hideCloverSettings.key)
                }
        }
        
        var showOpenInBrowser: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.showOpenInBrowser.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.showOpenInBrowser.key)
                }
        }
        
        var hideKernelExtensions: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.hideKernelExtensions.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.hideKernelExtensions.key)
                }
        }
        
        var hidePackageInstaller: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.hidePackageInstaller.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.hidePackageInstaller.key)
                }
        }
        
        var openInBrowserUrl: String {
                get {
                        return userDefaults.string(forKey: WebDriverManager.openInBrowserUrl.key) ?? ""
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.openInBrowserUrl.key)
                }
        }
        
        var openInBrowserTitle: String {
                get {
                        return userDefaults.string(forKey: WebDriverManager.openInBrowserTitle.key) ?? ""
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.openInBrowserTitle.key)
                }
        }
        
        var hoursAfterCheck: Int {
                get {
                        return userDefaults.integer(forKey: WebDriverManager.hoursAfterCheck.key)
                }
        }

        private func registerFactoryDefaults() {
                var factoryDefaults: [String : Any] = [:]
                if debug {
                        factoryDefaults = [WebDriverManager.initialized.key: true, WebDriverManager.showRestartAlert.key: true, WebDriverManager.suppressVersion.key: "", WebDriverManager.disableUpdateAlerts.key: true, WebDriverManager.hideBootArguments.key: false, WebDriverManager.hideCloverSettings.key: false, WebDriverManager.showOpenInBrowser.key: true, WebDriverManager.hideKernelExtensions.key: false, WebDriverManager.hidePackageInstaller.key: false, WebDriverManager.openInBrowserUrl.key: "https://vulgo.github.io/nvidia-drivers", WebDriverManager.openInBrowserTitle.key: "Nvidia Drivers", WebDriverManager.hoursAfterCheck.key: 6]
                } else {
                factoryDefaults = [WebDriverManager.initialized.key: true, WebDriverManager.showRestartAlert.key: true, WebDriverManager.suppressVersion.key: "", WebDriverManager.disableUpdateAlerts.key: true, WebDriverManager.hideBootArguments.key: true, WebDriverManager.hideCloverSettings.key: true, WebDriverManager.showOpenInBrowser.key: true, WebDriverManager.hideKernelExtensions.key: true, WebDriverManager.hidePackageInstaller.key: false, WebDriverManager.openInBrowserUrl.key: "https://vulgo.github.io/nvidia-drivers", WebDriverManager.openInBrowserTitle.key: "Nvidia Drivers", WebDriverManager.hoursAfterCheck.key: 6]
                }
                userDefaults.register(defaults: factoryDefaults)
        }
        
        func reset() {
                userDefaults.removeObject(forKey: WebDriverManager.initialized.key)
                userDefaults.removeObject(forKey: WebDriverManager.showRestartAlert.key)
                userDefaults.removeObject(forKey: WebDriverManager.suppressVersion.key)
                userDefaults.removeObject(forKey: WebDriverManager.disableUpdateAlerts.key)
                userDefaults.removeObject(forKey: WebDriverManager.hideBootArguments.key)
                userDefaults.removeObject(forKey: WebDriverManager.hideCloverSettings.key)
                userDefaults.removeObject(forKey: WebDriverManager.showOpenInBrowser.key)
                userDefaults.removeObject(forKey: WebDriverManager.hideKernelExtensions.key)
                userDefaults.removeObject(forKey: WebDriverManager.hidePackageInstaller.key)
                userDefaults.removeObject(forKey: WebDriverManager.openInBrowserUrl.key)
                userDefaults.removeObject(forKey: WebDriverManager.openInBrowserTitle.key)
                userDefaults.removeObject(forKey: WebDriverManager.hoursAfterCheck.key)
                registerFactoryDefaults()
        }
}
