/*
 * File: Log.swift
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
import os.log

struct Log {
        static func debug(_ message: StaticString, _ arg: CVarArg = "") {
                os_log(message, log: .default, type: .debug, arg)
        }
        
        static func info(_ message: StaticString, _ arg: CVarArg = "") {
                os_log(message, log: .default, type: .info, arg)
        }
        
        static func log(_ message: StaticString, _ arg: CVarArg = "") {
                os_log(message, log: .default, type: .default, arg)
        }
        
        static func error(_ message: StaticString, _ arg: CVarArg = "") {
                os_log(message, log: .default, type: .error, arg)
        }
}
