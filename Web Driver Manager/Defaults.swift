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
                static let initialized: String = "initialized"
                static let showRestartAlert: String = "showRestartAlert"
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
                        return userDefaults.bool(forKey: WebDriverManager.initialized)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.initialized)
                }
        }
        
        var showRestartAlert: Bool {
                get {
                        return userDefaults.bool(forKey: WebDriverManager.showRestartAlert)
                }
                set {
                        userDefaults.set(newValue, forKey: WebDriverManager.showRestartAlert)
                }
        }

        private func registerFactoryDefaults() {
                let factoryDefaults = [WebDriverManager.initialized : true, WebDriverManager.showRestartAlert : true]
                        as [String : Any]
                userDefaults.register(defaults: factoryDefaults)
        }
        
        func reset() {
                userDefaults.removeObject(forKey: WebDriverManager.initialized)
                userDefaults.removeObject(forKey: WebDriverManager.showRestartAlert)
                registerFactoryDefaults()
        }
}
