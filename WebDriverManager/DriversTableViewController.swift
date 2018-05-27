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
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "DriversTableViewController")
        
        var updaterViewController: UpdaterViewController!
        @IBOutlet var tableView: NSTableView!
        let updates: Array<AnyObject>? = WebDriverUpdates.shared.updates
        var localVersion: String? = WebDriverUpdates.shared.localVersion
        let localBuild = WebDriverUpdates.shared.localBuild
        var dataWantsFiltering: Bool = true
        var tableData: Array<AnyObject>? = nil
        
        var localVersionRequiredOS: String? {
                let infoPlistUrl = URL.init(fileURLWithPath: "/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist")
                guard let info = NSDictionary.init(contentsOf: infoPlistUrl) else {
                        return nil
                }
                guard let ioKitPersonalities = info["IOKitPersonalities"] as? NSDictionary else {
                        return nil
                }
                guard let nvdaStartup = ioKitPersonalities["NVDAStartup"] as? NSDictionary else {
                        return nil
                }
                guard let compatibleBuild = nvdaStartup["NVDARequiredOS"] as? String else {
                        return nil
                }
                return compatibleBuild
        }
        
        func isInstalled(version: String?) -> Bool {
                if let version = version, version == localVersion {
                        return true
                } else {
                        return false
                }
        }
        
        func isCompatible(build: String?) -> Bool {
                if let build = build, build == localBuild {
                        return true
                } else {
                        return false
                }
        }
        
        func addOtherInstalledVersionAndSort() {
                var versions: [String] = Array()
                for update in tableData! {
                        if let version = update["version"] as? String {
                                versions.append(version)
                        }
                }
                if localVersion != nil, !versions.contains(localVersion!) {
                        var installed: [String: Any] = Dictionary()
                        installed["version"] = localVersion ?? "Unknown"
                        installed["OS"] = localVersionRequiredOS ?? "Unknown"
                        tableData?.append(installed as AnyObject)
                }
                tableData?.sort(by: {
                        (dictOne, dictTwo) -> Bool in
                        guard let buildOne = dictOne["OS"] as? String, let buildTwo = dictTwo["OS"] as? String else {
                                return false
                        }
                        if buildOne == buildTwo {
                                guard let versionOne = dictOne["version"] as? String, let versionTwo = dictTwo["version"] as? String else {
                                        return false
                                }
                                return versionOne > versionTwo
                        } else {
                                return buildOne > buildTwo
                        }
                })
        }
        
        func updateTableData() {
                
                os_log("Updating table data source", log: osLog, type: .default)
                localVersion = WebDriverUpdates.shared.localVersion
                guard updates != nil else {
                        os_log("Updates is nil", log: osLog, type: .default)
                        tableData = nil
                        return
                }
                if !dataWantsFiltering {
                        tableData = updates
                } else {
                        var filteredData: Array<AnyObject> = Array()
                        for update in updates! {
                                if isInstalled(version: update["version"] as? String) {
                                        os_log("Including installed version in filtered table data: %{public}@", log: osLog, type: .default, update["version"] as? String ?? "nil")
                                        filteredData.append(update)
                                        continue
                                }
                                if isCompatible(build: update["OS"] as? String) {
                                        os_log("Including compatible version in filtered table data: %{public}@", log: osLog, type: .default, update["version"] as? String ?? "nil")
                                        filteredData.append(update)
                                        continue
                                }
                        }
                        tableData = filteredData
                }
                addOtherInstalledVersionAndSort()
                tableView.reloadData()
        }

        override func viewDidLoad() {
                super.viewDidLoad()
                updaterViewController = parent as? UpdaterViewController
                tableView.delegate = self
                tableView.dataSource = self
                updaterViewController.update()
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
                return tableData?.count ?? 0
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
                guard let parent = parent as? UpdaterViewController else {
                        return
                }
                let selectedIndex = tableView.selectedRow
                guard selectedIndex != -1, let url = tableData?[selectedIndex]["downloadURL"] as? String, let checksum = tableData?[selectedIndex]["checksum"] as? String, let version = tableData?[selectedIndex]["version"] as? String else {
                        parent.installButton.isEnabled = false
                        return
                }
                parent.url = url
                parent.checksum = checksum
                parent.version = version
                parent.installButton.isEnabled = true
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
                
                guard let update = tableData?[row] else {
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
                        guard let cell = tableView.makeView(withIdentifier: id.cell.info, owner: nil) as? NSTableCellView else {
                                return nil
                        }
                        switch (isInstalled(version: update["version"] as? String), isCompatible(build: update["OS"] as? String)) {
                        case (false, true):
                                cell.textField?.stringValue = "Update available"
                        case (true, true):
                                cell.textField?.stringValue = "Installed"
                        case (true, false):
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
