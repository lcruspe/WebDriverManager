/*
 * File: Scripts.swift
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

class ShellScript: NSObject {
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Scripts")
        
        var url: URL?
        var path: String? {
                get {
                        return url?.path
                }
        }

        init(fromResource name: String, withExtension ext: String) {
                url = Bundle.main.url(forResource: name, withExtension: ext)
        }
        
        func executeReturningTerminationStatus(arguments: [Any]? = nil) -> Int32 {
                if let path = self.path {
                        var args: [Any] = arguments ?? [Any]()
                        args.insert(path as Any, at: 0)
                        let task = STPrivilegedTask()
                        task.arguments = args
                        task.launchPath = "/bin/sh"
                        let error = task.launch()
                        guard error == errAuthorizationSuccess else {
                                switch error {
                                case errAuthorizationCanceled:
                                        os_log("User cancelled authorization", log: osLog, type: .default)
                                        return -1
                                default:
                                        os_log("Authentication error", log: osLog, type: .default)
                                        return -1
                                }
                        }
                        task.waitUntilExit()
                        return task.terminationStatus
                } else {
                        return -1
                }
        }
}

struct Scripts {
        
        static let shared = Scripts()
        
        let bootArgs = ShellScript(fromResource: "bootArgs", withExtension: "sh")
        let clearStaging = ShellScript(fromResource: "clearStaging", withExtension: "sh")
        let component = ShellScript(fromResource: "component", withExtension: "sh")
        let deleteBootArgs = ShellScript(fromResource: "deleteBootArgs", withExtension: "sh")
        let nvram = ShellScript(fromResource: "nvram", withExtension: "sh")
        let patch = ShellScript(fromResource: "patch", withExtension: "sh")
        let product = ShellScript(fromResource: "product", withExtension: "sh")
        let touch = ShellScript(fromResource: "touch", withExtension: "sh")
        let unstage = ShellScript(fromResource: "unstage", withExtension: "sh")

}
