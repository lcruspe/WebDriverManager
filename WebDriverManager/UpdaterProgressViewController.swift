/*
 * File: UpdaterProgressViewController.swift
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

class UpdaterProgressViewController: NSViewController {
        
        @IBOutlet weak var closeButton: NSButton!
        @IBOutlet weak var progressIndicator: NSProgressIndicator!
        @IBOutlet weak var progressMessage: NSTextField!
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "UpdaterController")
        let task = STPrivilegedTask()
        var parentWindow: NSWindow?
        var progressObserver : NSObjectProtocol!
        var terminationObserver: NSObjectProtocol!
        var stdout: FileHandle?
        
        override func viewDidLoad() {
                
                super.viewDidLoad()
                closeButton.isEnabled = false
                progressMessage.stringValue = "Waiting for authorization..."
                os_log("Waiting for authorization", log: osLog, type: .default)
                
        }
        
        override func viewDidAppear() {

                view.window?.styleMask.remove(.resizable)
                
                if let thisSheet = self.view.window {
                        for window in NSApp.windows {
                                if window.attachedSheet == thisSheet {
                                        parentWindow = window
                                }
                        }
                }
                
                guard let parentViewController = parentWindow?.contentViewController as? UpdaterViewController else {
                        self.progressIndicator.doubleValue = 100.0
                        self.progressMessage.stringValue = "Error"
                        os_log("Failed to get a reference to the parent window", log: osLog, type: .default)
                        NSApp.activate(ignoringOtherApps: true)
                        parentWindow?.makeKeyAndOrderFront(self)
                        closeButton.isEnabled = true
                        return
                }
                
                guard let url: String = parentViewController.url, let checksum: String = parentViewController.checksum else {
                        view.window?.close()
                        return
                }

                task.launchPath = "/bin/sh"
                task.arguments = ["/git/webdriver.sh/WebDriverManager/install", url, checksum]
                task.terminationHandler = {
                        (task) -> Void in
                        sleep(1)
                        if self.progressIndicator.doubleValue != 100.0 {
                                self.progressIndicator.doubleValue = 100.0
                                self.progressMessage.stringValue = "Error: Task terminated unexpectedly"
                                os_log("Task terminated unexpectedly", log: self.osLog, type: .error)
                        } else {
                                os_log("STPrivilegedTask has terminated", log: self.osLog, type: .default)
                        }
                        NSApp.activate(ignoringOtherApps: true)
                        self.parentWindow?.makeKeyAndOrderFront(self)
                        self.closeButton.isEnabled = true
                }
                
                progressObserver = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdout, queue: nil) {
                        (notification) -> Void in
                        if let data = self.stdout?.availableData {
                                if data.count > 0 {
                                        guard let output = String(data: data, encoding: .utf8)?.split(separator: ":") else {
                                                return
                                        }
                                        guard output.count == 2 else {
                                                return
                                        }
                                        let numberString = String(output[0])
                                        let messageString = String(output[1])
                                        if numberString.uppercased() == "ERROR" {
                                                DispatchQueue.main.async {
                                                        self.progressIndicator.doubleValue = 100.0
                                                        self.progressMessage.stringValue = "Error: \(messageString)"
                                                }
                                                let logString = "webdriver.sh: \(messageString.replacingOccurrences(of: "...", with: ""))"
                                                os_log("%{public}@", log: self.osLog, type: .error, logString)
                                        } else {
                                                let scanner = Scanner.init(string: numberString)
                                                var number: Double = 0
                                                scanner.scanDouble(&number)
                                                DispatchQueue.main.async {
                                                        self.progressIndicator.doubleValue = number
                                                        self.progressMessage.stringValue = messageString
                                                }
                                                let logString = "webdriver.sh: \(messageString.replacingOccurrences(of: "...", with: ""))"
                                                os_log("%{public}@", log: self.osLog, type: .default, logString)
                                        }
                                        self.stdout?.waitForDataInBackgroundAndNotify()
                                        return
                                }
                                /* Notification with zero data length */
                                NotificationCenter.default.removeObserver(self.progressObserver)
                                DispatchQueue.main.async {
                                        self.closeButton.isEnabled = true
                                }
                        }
                }
                
                let error = task.launch()
                
                guard error == errAuthorizationSuccess else {
                        self.progressIndicator.doubleValue = 100.0
                        NSApp.activate(ignoringOtherApps: true)
                        parentWindow?.makeKeyAndOrderFront(self)
                        closeButton.isEnabled = true
                        switch error {
                        case errAuthorizationCanceled:
                                self.progressMessage.stringValue = "Error: Authorization canceled"
                                os_log("User cancelled authorization", log: osLog, type: .default)
                                return
                        default:
                                self.progressMessage.stringValue = "Error: Authentication error"
                                os_log("Authorization error", log: osLog, type: .default)
                                return
                        }
                }
                
                os_log("Authorization sucess", log: osLog, type: .default)
                NSApp.activate(ignoringOtherApps: true)
                parentWindow?.makeKeyAndOrderFront(self)
                stdout = task.outputFileHandle
                stdout?.waitForDataInBackgroundAndNotify()
                
        }
        
        @IBAction func closeButtonPressed(_ sender: Any) {
                view.window?.close()
        }
        
}
