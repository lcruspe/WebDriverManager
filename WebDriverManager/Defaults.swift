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
                case bootArgumentsIsVisible
                case cloverSettingsIsVisible
                case kernelExtensionsIsVisible
                case packageInstallerIsVisible
                case openInBrowserIsVisible
                case openInBrowserUrl
                case openInBrowserDescription
                case hoursAfterCheck
                case stageGPUBundles
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
                        case .bootArgumentsIsVisible:
                                return "bootArgumentsIsVisible"
                        case .cloverSettingsIsVisible:
                                return "cloverSettingsIsVisible"
                        case .kernelExtensionsIsVisible:
                                return "kernelExtensionsIsVisible"
                        case .packageInstallerIsVisible:
                                return "packageInstallerIsVisible"
                        case .openInBrowserIsVisible:
                                return "openInBrowserIsVisible"
                        case .openInBrowserUrl:
                                return "openInBrowserUrl"
                        case .openInBrowserDescription:
                                return "openInBrowserDescription"
                        case .hoursAfterCheck:
                                return "hoursAfterCheck"
                        case .stageGPUBundles:
                                return "stageGPUBundles"
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
        
        var bootArgumentsIsVisible: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.bootArgumentsIsVisible.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.bootArgumentsIsVisible.key)
                }
        }
        
        var cloverSettingsIsVisible: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.cloverSettingsIsVisible.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.cloverSettingsIsVisible.key)
                }
        }
        
        var kernelExtensionsIsVisible: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.kernelExtensionsIsVisible.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.kernelExtensionsIsVisible.key)
                }
        }
        
        var packageInstallerIsVisible: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.packageInstallerIsVisible.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.packageInstallerIsVisible.key)
                }
        }
        
        var openInBrowserIsVisible: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.openInBrowserIsVisible.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.openInBrowserIsVisible.key)
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
                        return userDefaults.string(forKey: WebDriverManager.openInBrowserDescription.key) ?? ""
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.openInBrowserDescription.key)
                }
        }
        
        var hoursAfterCheck: Int {
                get {
                        return userDefaults.integer(forKey: WebDriverManager.hoursAfterCheck.key)
                }
        }
        
        var stageGPUBundles: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.stageGPUBundles.key)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.stageGPUBundles.key)
                }
        }

        private func registerFactoryDefaults() {
                let factoryDefaults: [String: Any] = [
                        WebDriverManager.initialized.key: true,
                        WebDriverManager.showRestartAlert.key: true,
                        WebDriverManager.suppressVersion.key: "",
                        WebDriverManager.disableUpdateAlerts.key: true,
                        WebDriverManager.bootArgumentsIsVisible.key: false,
                        WebDriverManager.cloverSettingsIsVisible.key: true,
                        WebDriverManager.kernelExtensionsIsVisible.key: false,
                        WebDriverManager.packageInstallerIsVisible.key: true,
                        WebDriverManager.openInBrowserIsVisible.key: true,
                        WebDriverManager.openInBrowserUrl.key: "https://vulgo.github.io/nvidia-drivers",
                        WebDriverManager.openInBrowserDescription.key: "Nvidia Drivers",
                        WebDriverManager.hoursAfterCheck.key: 6,
                        WebDriverManager.stageGPUBundles.key: true
                ]
                userDefaults.register(defaults: factoryDefaults)
        }
        
        func reset() {
                userDefaults.removeObject(forKey: WebDriverManager.initialized.key)
                userDefaults.removeObject(forKey: WebDriverManager.showRestartAlert.key)
                userDefaults.removeObject(forKey: WebDriverManager.suppressVersion.key)
                userDefaults.removeObject(forKey: WebDriverManager.disableUpdateAlerts.key)
                userDefaults.removeObject(forKey: WebDriverManager.bootArgumentsIsVisible.key)
                userDefaults.removeObject(forKey: WebDriverManager.cloverSettingsIsVisible.key)
                userDefaults.removeObject(forKey: WebDriverManager.kernelExtensionsIsVisible.key)
                userDefaults.removeObject(forKey: WebDriverManager.packageInstallerIsVisible.key)
                userDefaults.removeObject(forKey: WebDriverManager.openInBrowserIsVisible.key)
                userDefaults.removeObject(forKey: WebDriverManager.openInBrowserUrl.key)
                userDefaults.removeObject(forKey: WebDriverManager.openInBrowserDescription.key)
                userDefaults.removeObject(forKey: WebDriverManager.hoursAfterCheck.key)
                userDefaults.removeObject(forKey: WebDriverManager.stageGPUBundles.key)
                registerFactoryDefaults()
        }
}
