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
        
        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "UpdaterController")
        
        @IBOutlet weak var closeButton: NSButton!
        @IBOutlet weak var progressIndicator: NSProgressIndicator!
        @IBOutlet weak var progressMessage: NSTextField!
        
        var parentWindow: NSWindow?
        var progressObserver : NSObjectProtocol!
        var terminationObserver: NSObjectProtocol!
        var stdout: FileHandle?
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        override func dismiss(_ sender: Any?) {
                progressMessage.stringValue = ""
                progressIndicator.doubleValue = 0.0
                super.dismiss(sender)
        }
        
        override func viewDidAppear() {
                super.viewDidAppear()
                DispatchQueue.main.async {
                        self.closeButton.isEnabled = false
                        self.progressMessage.stringValue = "Waiting for authorization..."
                        self.progressIndicator.doubleValue = 0.0
                        self.view.window?.styleMask.remove(.resizable)
                }
                
                let task = STPrivilegedTask()
                
                os_log("Waiting for authorization", log: osLog, type: .default)
                if let thisSheet = view.window {
                        for window in NSApp.windows {
                                if window.attachedSheet == thisSheet {
                                        parentWindow = window
                                }
                        }
                }
                
                guard let parentViewController = parentWindow?.contentViewController as? UpdaterViewController else {
                        DispatchQueue.main.async {
                                self.progressIndicator.doubleValue = 100.0
                                self.progressMessage.stringValue = "Error"
                                self.closeButton.isEnabled = true
                        }
                        os_log("Failed to get a reference to the parent window", log: osLog, type: .default)
                        NSApp.activate(ignoringOtherApps: true)
                        parentWindow?.makeKeyAndOrderFront(self)

                        return
                }
                
                guard let url: String = parentViewController.url, let checksum: String = parentViewController.checksum else {
                        dismiss(self)
                        return
                }

                task.launchPath = "/bin/sh"
                
                guard let action = parentViewController.action else {
                        NotificationCenter.default.removeObserver(self.progressObserver)
                        dismiss(self)
                        return
                }
                
                switch action {
                case .installSelected:
                        let scriptUrl = Bundle.main.url(forResource: "install", withExtension: "sh")
                        let stageGPUBundles: Int = Defaults.shared.stageGPUBundles ? 1 : 0
                        task.arguments = [scriptUrl!.path, url, checksum, String(stageGPUBundles)]
                case .uninstall:
                        let scriptUrl = Bundle.main.url(forResource: "uninstall", withExtension: "sh")
                        task.arguments = [scriptUrl!.path]
                }
                
                parentViewController.action = nil

                task.terminationHandler = {
                        (task) -> Void in
                        os_log("STPrivilegedTask has terminated", log: self.osLog, type: .default)
                        self.closeButton.isEnabled = true
                }
                
                progressObserver = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdout, queue: nil) {
                        (notification) -> Void in
                        guard let data = self.stdout?.availableData else {
                                self.stdout?.waitForDataInBackgroundAndNotify()
                                return
                        }
                        switch data.count {
                        case 0:
                                NotificationCenter.default.removeObserver(self.progressObserver)
                                DispatchQueue.main.async {
                                        self.closeButton.isEnabled = true
                                }
                        default:
                                guard let output = String(data: data, encoding: .utf8)?.split(separator: ":"), output.count == 2  else {
                                        self.stdout?.waitForDataInBackgroundAndNotify()
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
                        }
                }
                

                let error = task.launch()

                guard error == errAuthorizationSuccess else {
                        NSApp.activate(ignoringOtherApps: true)
                        parentWindow?.makeKeyAndOrderFront(self)
                        switch error {
                        case errAuthorizationCanceled:
                                os_log("User cancelled authorization", log: osLog, type: .default)
                                DispatchQueue.main.async {
                                        self.dismiss(self)
                                }
                                return
                        default:
                                DispatchQueue.main.async {
                                        self.progressIndicator.doubleValue = 100.0
                                        self.closeButton.isEnabled = true
                                        self.progressMessage.stringValue = "Error: Authentication error"
                                }
                                os_log("Authentication error", log: osLog, type: .default)
                                return
                        }
                }

                DispatchQueue.main.async {
                        self.progressMessage.stringValue = ""
                }
                os_log("Authorization sucess", log: osLog, type: .default)
                NSApp.activate(ignoringOtherApps: true)
                parentWindow?.makeKeyAndOrderFront(self)
                stdout = task.outputFileHandle
                stdout?.waitForDataInBackgroundAndNotify() 
        }
        
        @IBAction func closeButtonPressed(_ sender: Any) {
                (parentWindow?.contentViewController as? UpdaterViewController)?.update()
                dismiss(self)
        }
        
}
