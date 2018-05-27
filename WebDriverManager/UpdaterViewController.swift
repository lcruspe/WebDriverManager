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
        @IBOutlet weak var cacheTimeTextField: NSTextField!
        @IBOutlet weak var installButton: NSButton!
        @IBOutlet weak var filterButton: NSButton!
        @IBOutlet weak var runningOnTextField: NSTextField!
        
        var updaterProgressViewController: UpdaterProgressViewController?
        let driversTableViewController = DriversTableViewController()
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "UpdaterControllerMainWindow")
        var url: String?
        var checksum: String?
        var version: String?
        let macOSProductBuildString = "\(sysctl(byName: "kern.osproductversion") ?? "??") \(WebDriverUpdates.shared.localBuild ?? "??")"
        var filteredHeight: NSLayoutConstraint?
        var unfilteredHeight: NSLayoutConstraint?
        
        enum Action {
                case installSelected, uninstall
        }
        var action: Action? = nil
        
        func showReinstallAlert(version: String) -> Bool {
                let alert = NSAlert()
                alert.addButton(withTitle: "Reinstall")
                alert.addButton(withTitle: "Cancel")
                alert.messageText = "Installing \(version)"
                alert.informativeText = "That version is already installed."
                let response = alert.runModal()
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                        return true
                } else {
                        return false
                }
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                filteredHeight = updatesTableContainerView.heightAnchor.constraint(equalToConstant: 78.0)
                unfilteredHeight = updatesTableContainerView.heightAnchor.constraint(equalToConstant: 390.0)
        }
        
        override func viewDidAppear() {
                if !childViewControllers.contains(driversTableViewController) {
                        addChildViewController(driversTableViewController)
                        driversTableViewController.view.frame = updatesTableContainerView.bounds
                        updatesTableContainerView.addSubview(driversTableViewController.view)
                }
                switch driversTableViewController.dataWantsFiltering {
                case false:
                        filterButton.state = .off
                        updatesTableContainerView.removeConstraint(filteredHeight!)
                        updatesTableContainerView.addConstraint(unfilteredHeight!)
                default:
                        filterButton.state = .on
                        updatesTableContainerView.removeConstraint(unfilteredHeight!)
                        updatesTableContainerView.addConstraint(filteredHeight!)
                }
                runningOnTextField.stringValue = macOSProductBuildString
        }
        
        func update() {
                driversTableViewController.updateTableData()
                driversTableViewController.tableView.reloadData()
                let time = WebDriverUpdates.shared.cacheTime
                let displayTime: String = time?.description(with: .current) ?? ""
                cacheTimeTextField.stringValue = displayTime
        }
        
        @IBAction func filterButtonPressed(_ button: NSButton) {
                switch button.state {
                case .off:
                        driversTableViewController.dataWantsFiltering = false
                        updatesTableContainerView.removeConstraint(filteredHeight!)
                        updatesTableContainerView.addConstraint(unfilteredHeight!)
                default:
                        driversTableViewController.dataWantsFiltering = true
                        updatesTableContainerView.removeConstraint(unfilteredHeight!)
                        updatesTableContainerView.addConstraint(filteredHeight!)
                }
                update()
        }
        
        @IBAction func installButtonPressed(_ button: NSButton) {
                if WebDriverUpdates.shared.localVersion == version, let version = version {
                        guard showReinstallAlert(version: version) else {
                                return
                        }
                }
                action = .installSelected
                updaterProgressViewController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "updaterProgress")) as? UpdaterProgressViewController
                self.presentViewControllerAsSheet(self.updaterProgressViewController!)                
        }
        
        @IBAction func uninstallButtonPressed(_ button: NSButton) {
                action = .uninstall
                updaterProgressViewController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "updaterProgress")) as? UpdaterProgressViewController
                self.presentViewControllerAsSheet(self.updaterProgressViewController!)
        }
        
        @IBAction func refreshButtonPressed(_ sender: NSButton) {
                sender.isEnabled = false
                let refreshResult = WebDriverUpdates.shared.refresh()
                if refreshResult {
                        update()
                        os_log("User refresh OK", log: osLog, type: .default)
                } else {
                        os_log("User refresh failed", log: osLog, type: .default)
                }
                sender.isEnabled = true
        }
        
}
