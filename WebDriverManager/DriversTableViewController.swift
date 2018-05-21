/*
 * File: DriversTableViewController.swift
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

class DriversTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
        
        var updaterViewController: UpdaterViewController!
        @IBOutlet var tableView: NSTableView!
        let updates: Array<AnyObject>? = WebDriverUpdates.shared.updates
        var localVersion: String?
        var localBuild: String?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                updaterViewController = parent as? UpdaterViewController
                tableView.delegate = self
                tableView.dataSource = self
                localVersion = WebDriverUpdates.shared.localVersion
                localBuild = WebDriverUpdates.shared.build
        }
        
        override func viewDidAppear() {
                //
        }
        
        /* Table View Delegate */
        
        struct id {
                enum cell {
                        static let none = NSUserInterfaceItemIdentifier(rawValue: "")
                        static let version = NSUserInterfaceItemIdentifier(rawValue: "version")
                        static let build = NSUserInterfaceItemIdentifier(rawValue: "build")
                        static let info = NSUserInterfaceItemIdentifier(rawValue: "info")
                }
                enum column {
                        static let none = NSUserInterfaceItemIdentifier(rawValue: "")
                        static let version = NSUserInterfaceItemIdentifier(rawValue: "version")
                        static let build = NSUserInterfaceItemIdentifier(rawValue: "build")
                        static let info = NSUserInterfaceItemIdentifier(rawValue: "info")
                }
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
                return updates?.count ?? 0
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
                
                guard let update = updates?[row] else {
                        return nil
                }
                
                switch tableColumn?.identifier {
                        
                case id.column.version:
                        if let cell = tableView.makeView(withIdentifier: id.cell.version, owner: nil) as? NSTableCellView {
                                cell.textField?.stringValue = update["version"] as? String ?? "Error"
                                return cell
                        } else {
                                return nil
                        }
                        
                case id.column.build:
                        if let cell = tableView.makeView(withIdentifier: id.cell.build, owner: nil) as? NSTableCellView {
                                cell.textField?.stringValue = update["OS"] as? String ?? "Error"
                                return cell
                        } else {
                                return nil
                        }
                        
                case id.column.info:
                        var isInstalled: Bool = false
                        var isAvailable: Bool = false
                        guard let cell = tableView.makeView(withIdentifier: id.cell.info, owner: nil) as? NSTableCellView else {
                                return nil
                        }
                        if let version = update["version"] as? String, version == localVersion {
                                isInstalled = true
                        }
                        if let build = update["OS"] as? String, build == localBuild {
                                isAvailable = true
                        }
                        switch (isAvailable, isInstalled) {
                        case (true, false):
                                cell.textField?.stringValue = "Update available"
                        case (true, true):
                                cell.textField?.stringValue = "Already installed"
                        case (false, true):
                                cell.textField?.stringValue = "Installed"
                        default:
                                cell.textField?.stringValue = ""
                        }
                        return cell
                        
                default:
                        return nil
                }
                
        }
       
}
