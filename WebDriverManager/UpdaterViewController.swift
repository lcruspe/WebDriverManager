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
        @IBOutlet weak var driversTableHeight: NSLayoutConstraint!
        
        var updaterProgressViewController: UpdaterProgressViewController?
        let driversTableViewController = DriversTableViewController()
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "UpdaterControllerMainWindow")
        var url: String?
        var checksum: String?
        var version: String?
        let macOSProductBuildString = "\(sysctl(byName: "kern.osproductversion") ?? "??") \(WebDriverUpdates.shared.localBuild ?? "??")"
        let filteredHeight: CGFloat = 78.0
        let unfilteredHeight: CGFloat = 390.0
        
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
                        driversTableHeight.constant = unfilteredHeight
                default:
                        filterButton.state = .on
                        driversTableHeight.constant = filteredHeight
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
                driversTableViewController.hideScrollers()
                switch button.state {
                case .off:
                        driversTableViewController.dataWantsFiltering = false
                        NSAnimationContext.runAnimationGroup({
                                context in
                                context.duration = 0.25
                                driversTableHeight.animator().constant = unfilteredHeight
                        }, completionHandler: {
                                self.update()
                                self.driversTableViewController.unhideScrollers()
                        })
                default:
                        driversTableViewController.dataWantsFiltering = true
                        NSAnimationContext.runAnimationGroup({
                                context in
                                context.duration = 0.25
                                driversTableHeight.animator().constant = filteredHeight
                        }, completionHandler: {
                                self.update()
                                self.driversTableViewController.unhideScrollers()
                        })
                }
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
                cacheTimeTextField.stringValue = "Downloading updates data from NVIDIA..."
                let indexSet = IndexSet(integersIn: 0...driversTableViewController.tableView.numberOfRows - 1)
                NSAnimationContext.runAnimationGroup({
                        context in
                        context.duration = 0.25
                        driversTableViewController.tableView.removeRows(at: indexSet, withAnimation: .effectFade)
                }, completionHandler: {
                        let refreshResult = WebDriverUpdates.shared.refresh()
                        if refreshResult {
                                self.update()
                                os_log("User refresh OK", log: self.osLog, type: .default)
                        } else {
                                os_log("User refresh failed", log: self.osLog, type: .default)
                        }
                        sender.isEnabled = true
                })

        }
        
}
