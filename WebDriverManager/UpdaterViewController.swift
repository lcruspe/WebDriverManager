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
        
        @IBOutlet weak var updatesTableContainerView: NSView!
        @IBOutlet weak var installButton: NSButton!
        let drivers = DriversTableViewController()
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "UpdaterControllerMainWindow")
        var url: String?
        var checksum: String?
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        override func viewDidAppear() {
                if !childViewControllers.contains(drivers) {
                        addChildViewController(drivers)
                        drivers.view.frame = updatesTableContainerView.bounds
                        updatesTableContainerView.addSubview(drivers.view)
                }
        }
        
}
