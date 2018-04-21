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

struct Scripts {
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Scripts")
        var error: NSDictionary?
        var nvram: NSAppleScript?
        var unstage: NSAppleScript?
        var touch: NSAppleScript?
        var clearStaging: NSAppleScript?
        
        init() {
                if let nvramScriptUrl = Bundle.main.url(forResource: "nvram", withExtension: "applescript") {
                        nvram = NSAppleScript(contentsOf: nvramScriptUrl, error: &error)
                } else {
                        os_log("Failed to get resource url for nvram script", log: osLog, type: .default)
                }
                if let unstageScriptUrl = Bundle.main.url(forResource: "unstage", withExtension: "applescript") {
                        unstage = NSAppleScript(contentsOf: unstageScriptUrl, error: &error)
                } else {
                        os_log("Failed to get resource url for unstage script", log: osLog, type: .default)
                }
                if let touchScriptUrl = Bundle.main.url(forResource: "touch", withExtension: "applescript") {
                        touch = NSAppleScript(contentsOf: touchScriptUrl, error: &error)
                } else {
                        os_log("Failed to get resource url for touch script", log: osLog, type: .default)
                }
                if let clearStagingScriptUrl = Bundle.main.url(forResource: "clearStaging", withExtension: "applescript") {
                        clearStaging = NSAppleScript(contentsOf: clearStagingScriptUrl, error: &error)
                } else {
                        os_log("Failed to get resource URL for clear staging script", log: osLog, type: .default)
                }
        }
        
        func boolValue(_ eventDescriptor: NSAppleEventDescriptor?) -> Bool {
                if let bool = eventDescriptor?.booleanValue, bool == true {
                        return true
                }
                return false
        }
}
