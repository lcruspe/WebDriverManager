/*
 * File: UpdaterViewController.swift
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

class UpdaterViewController: NSViewController {
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "UpdaterControllerMainWindow")
        let url = "https://images.nvidia.com/mac/pkg/387/WebDriver-387.10.10.10.30.107.pkg"
        let checksum = "c6e258a40f344a6594d2ea50722a6f7d90d93fcd001a9e458b04077612cef65050401b0435c392c550d40b95737791955ffef0e4b149b64ff2b9758592733b02"
        
        override func viewDidLoad() {
                super.viewDidLoad()
                // Do view setup here.
        }
        
}
