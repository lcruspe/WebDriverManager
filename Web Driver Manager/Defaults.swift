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

#if DEBUG
let debug = true
#else
let debug = false
#endif

import Foundation

class Defaults {
        
        static let shared = Defaults()
        let userDefaults = UserDefaults.standard
        
        enum WebDriverManager {
                case initialized
                case showRestartAlert
                case suppressVersion
                case disableUpdateAlerts
                
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

        private func registerFactoryDefaults() {
                let factoryDefaults = [WebDriverManager.initialized.key: true, WebDriverManager.showRestartAlert.key: true, WebDriverManager.suppressVersion.key: "", WebDriverManager.disableUpdateAlerts.key: false]
                        as [String : Any]
                userDefaults.register(defaults: factoryDefaults)
        }
        
        func reset() {
                userDefaults.removeObject(forKey: WebDriverManager.initialized.key)
                userDefaults.removeObject(forKey: WebDriverManager.showRestartAlert.key)
                userDefaults.removeObject(forKey: WebDriverManager.suppressVersion.key)
                userDefaults.removeObject(forKey: WebDriverManager.disableUpdateAlerts.key)
                registerFactoryDefaults()
        }
}
