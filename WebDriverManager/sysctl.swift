/*
 * File: sysctl.swift
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

func sysctl(name: String) -> String? {
        let bufferSize = 256
        var buffer = Array<CChar>(repeating: 0, count: bufferSize)
        var size = size_t(buffer.count)
        let result: Int32 = sysctlbyname(name, &buffer, &size, nil, 0)
        if result != 0 {
                return nil
        } else {
                return buffer.withUnsafeBufferPointer { ptr -> String in
                        let string = String(cString: ptr.baseAddress!)
                        return string
                }
        }
}
