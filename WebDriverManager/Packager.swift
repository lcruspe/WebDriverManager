/*
 * File: Packager.swift
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

class Packager {

        let fileManager = FileManager()
        let packagerQueue = DispatchQueue(label: "packager", attributes: .concurrent)
        var packagerWorkItem: DispatchWorkItem?
        let nvidiaIdentifier = "NVWebDrivers"
        
        @discardableResult func list(archive: String) -> String? {
                let task = Process()
                task.launchPath = "/usr/bin/xar"
                task.arguments = ["-tf", archive]
                let stdout = Pipe()
                task.standardOutput = stdout
                if !debug {
                        task.standardError = Pipe()
                }
                task.launch()
                task.waitUntilExit()
                if let string = NSString.init(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8.rawValue) {
                        return string as String
                }
                return nil
        }
        
        @discardableResult func buildComponent(sourceDirectory: String, name: String) -> Int32 {
                let task = Process()
                task.launchPath = Bundle.main.url(forResource: "component", withExtension: "sh")?.path
                task.arguments = [sourceDirectory, name, name]
                if !debug {
                        task.standardOutput = Pipe()
                        task.standardError = Pipe()
                }
                task.launch()
                task.waitUntilExit()
                return (task.terminationStatus)
        }
        
        @discardableResult func buildProduct(sourceDirectory: String, outputName: String) -> Int32 {
                let task = Process()
                task.launchPath = Bundle.main.url(forResource: "product", withExtension: "sh")?.path
                task.arguments = [sourceDirectory, outputName]
                if !debug {
                        task.standardOutput = Pipe()
                        task.standardError = Pipe()
                }
                task.launch()
                task.waitUntilExit()
                return (task.terminationStatus)
        }
        
        @discardableResult func extract(archive: String, destinationDirectory directory: String) -> Int32 {
                let task = Process()
                task.launchPath = "/usr/bin/xar"
                task.currentDirectoryPath = directory
                task.arguments = ["-xf", archive]
                if !debug {
                        task.standardOutput = Pipe()
                        task.standardError = Pipe()
                }
                task.launch()
                task.waitUntilExit()
                return (task.terminationStatus)
        }
        
        @discardableResult func launchInstaller(package: String) -> Int32 {
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = ["-b", "com.apple.installer", "--args", package]
                if !debug {
                        task.standardOutput = Pipe()
                        task.standardError = Pipe()
                }
                task.launch()
                task.waitUntilExit()
                return (task.terminationStatus)
        }
        
        func start(atUrl url: URL) {
                packagerQueue.async {
                        self.packagerDidFinish(result: self._start(url))
                }
        }
        
        private func packagerDidFinish(result: Bool) {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.showPackageDropMenuItem.isEnabled = true
                }
        }
        
        private func _start(_ url: URL) -> Bool {
                let base = NSTemporaryDirectory()
                let uuid = NSUUID().uuidString
                let temp = "\(base)\(uuid)"
                let extracted = "\(temp)/tmp"
                if !fileManager.fileExists(atPath: url.path) {
                        os_log("Packager: Package or other file type not found")
                        return false
                }
                let fileList: String = list(archive: url.path) ?? ""
                if !fileList.contains(nvidiaIdentifier) {
                        NSSound.beep()
                        os_log("Packager: NVIDIA driver package not detected")
                        return false
                }
                /* Close package drop window */
                if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.packageDropController?.close()
                }
                do {
                        try fileManager.removeItem(atPath: temp)
                } catch {
                        if debug {
                                os_log("Packager: Nothing to remove")
                        }
                }
                do {
                        try fileManager.createDirectory(atPath: extracted, withIntermediateDirectories: true, attributes: nil)
                } catch {
                        os_log("Packager: Failed to create temporary directory")
                        return false
                }
                if debug {
                        os_log("Packager: Extracting to %{public}@", extracted)
                }
                if extract(archive: url.path, destinationDirectory: extracted) != 0 {
                        os_log("Packager: Failed to extract package")
                        return false
                }
                let distribution = "\(extracted)/Distribution"
                if !fileManager.fileExists(atPath: distribution) {
                        os_log("Packager: Distribution not found")
                        return false
                }
                let xml = Liberator(URL.init(fileURLWithPath: distribution))
                var name: String
                var version: String
                if let result = xml.liberate() {
                        name = result.0
                        version = result.1
                } else {
                        os_log("Packager: Failed to patch Distribution")
                        return false
                }
                
                if let welcome = Bundle.main.url(forResource: "Welcome", withExtension: "rtf") {
                        let existing = URL.init(fileURLWithPath: "\(extracted)/Resources/en.lproj/Welcome.rtf")
                        if fileManager.fileExists(atPath: existing.path) {
                                do {
                                        try fileManager.removeItem(at: existing)
                                } catch {
                                }
                                do {
                                        try fileManager.copyItem(at: welcome, to: existing)
                                } catch {
                                }
                        }
                }
                
                if let background = Bundle.main.url(forResource: "background", withExtension: "png") {
                        let existing = URL.init(fileURLWithPath: "\(extracted)/Resources/background.png")
                        if fileManager.fileExists(atPath: existing.path) {
                                do {
                                        try fileManager.removeItem(at: existing)
                                } catch {
                                }
                                do {
                                        try fileManager.copyItem(at: background, to: existing)
                                } catch {
                                }
                        }
                }
                
                buildComponent(sourceDirectory: extracted, name: name)
                if fileManager.fileExists(atPath: "\(temp)/\(name)") {
                        os_log("Packager: New drivers component exists")
                } else {
                        os_log("Packager: New drivers component doesn't exist")
                        return false
                }
                
                let outputPackageName = "NVIDIA-\(version).pkg"
                
                buildProduct(sourceDirectory: extracted, outputName: outputPackageName)
                let outputPackagePath = "\(temp)/\(outputPackageName)"
                if fileManager.fileExists(atPath: outputPackagePath) {
                        os_log("Packager: New product package exists")
                } else {
                        os_log("Packager: New product package doesn't exist")
                        return false
                }
                var desktopPath: String = ""
                if let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first?.appendingPathComponent(outputPackageName) {
                        desktopPath = desktop.path
                        do {
                                try fileManager.removeItem(at: desktop)
                        } catch {
                                if debug {
                                        os_log("Nothing to remove")
                                }
                        }
                        do {
                                try fileManager.copyItem(at: URL.init(fileURLWithPath: outputPackagePath), to: desktop)
                        } catch {
                                os_log("Packager: Failed to make a copy of driver package on the desktop")
                        }
                }
                if debug {
                        os_log("Packager: Will attempt to launch GUI installer for %{public}@", desktopPath)
                } else {
                        os_log("Packager: Will attempt to launch GUI installer")
                }
                var result: Bool
                if launchInstaller(package: desktopPath) == 0 {
                        os_log("Packager: Open command completed with success")
                        result = true
                } else {
                        os_log("Packager: Open command returned a non-zero exit status")
                        result = false
                }
                let tempUrl = URL.init(fileURLWithPath: temp)
                do {
                        try fileManager.removeItem(at: tempUrl)
                } catch {
                        os_log("Packager: Failed to remove temporary directory")
                }
                return result
        }
}
