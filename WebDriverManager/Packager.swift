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

        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Packager")
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
        
        func processPackage(atUrl url: URL) {
                packagerQueue.async {
                        self.packagerDidFinish(result: self.processPackage(url))
                }
        }
        
        private func packagerDidFinish(result: Bool) {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.showPackageDropMenuItem.isEnabled = true
                }
        }
        
        private func processPackage(_ url: URL) -> Bool {
                os_log("Processing dropped package...", log: osLog, type: .info)
                if !fileManager.fileExists(atPath: url.path) {
                        os_log("Package or other file type not found", log: osLog, type: .default)
                        return false
                }
                let fileList: String = list(archive: url.path) ?? ""
                if !fileList.contains(nvidiaIdentifier) {
                        NSSound.beep()
                        os_log("NVIDIA driver package not detected", log: osLog, type: .default)
                        return false
                }
                
                /* Close package drop window */
                
                if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.packageDropController?.close()
                }
                let temporaryDirectory = "\(NSTemporaryDirectory())\(NSUUID().uuidString)"
                let removeTemporaryDirectory = {
                        do {
                                try self.fileManager.removeItem(at: URL.init(fileURLWithPath: temporaryDirectory))
                        } catch {
                                os_log("Failed to remove temporary directory", log: self.osLog, type: .default)
                        }
                }
                let extracted = "\(temporaryDirectory)/tmp"
                removeTemporaryDirectory()
                do {
                        try fileManager.createDirectory(atPath: extracted, withIntermediateDirectories: true, attributes: nil)
                } catch {
                        os_log("Failed to create temporary directory", log: osLog, type: .default)
                        removeTemporaryDirectory()
                        return false
                }
                if debug {
                        os_log("Extracting to %{public}@", log: osLog, type: .info, extracted)
                }
                if extract(archive: url.path, destinationDirectory: extracted) != 0 {
                        removeTemporaryDirectory()
                        os_log("Failed to extract package", log: osLog, type: .default)
                        return false
                }
                let distribution = "\(extracted)/Distribution"
                if !fileManager.fileExists(atPath: distribution) {
                        os_log("Distribution not found", log: osLog, type: .default)
                        removeTemporaryDirectory()
                        return false
                }
                let xml = Liberator(URL.init(fileURLWithPath: distribution))
                var name: String
                var version: String
                if let result = xml.liberate() {
                        name = result.0
                        version = result.1
                } else {
                        os_log("Failed to patch Distribution", log: osLog, type: .default)
                        removeTemporaryDirectory()
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
                
                os_log("Building driver component package...", log: osLog, type: .info)
                buildComponent(sourceDirectory: extracted, name: name)
                if fileManager.fileExists(atPath: "\(temporaryDirectory)/\(name)") {
                        os_log("New drivers component exists", log: osLog, type: .info)
                } else {
                        os_log("New drivers component doesn't exist", log: osLog, type: .default)
                        removeTemporaryDirectory()
                        return false
                }
                
                let outputPackageName = "NVIDIA-\(version).pkg"
                
                os_log("Building product package...", log: osLog, type: .info)
                buildProduct(sourceDirectory: extracted, outputName: outputPackageName)
                let outputPackagePath = "\(temporaryDirectory)/\(outputPackageName)"
                if fileManager.fileExists(atPath: outputPackagePath) {
                        os_log("New product package exists", log: osLog, type: .info)
                } else {
                        os_log("New product package doesn't exist", log: osLog, type: .default)
                        removeTemporaryDirectory()
                        return false
                }
                var desktopPath: String = ""
                if let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first?.appendingPathComponent(outputPackageName) {
                        desktopPath = desktop.path
                        do {
                                try fileManager.removeItem(at: desktop)
                        } catch {
                                if debug {
                                        os_log("Nothing to remove", log: osLog, type: .info)
                                }
                        }
                        do {
                                try fileManager.copyItem(at: URL.init(fileURLWithPath: outputPackagePath), to: desktop)
                        } catch {
                                os_log("Failed to make a copy of driver package on the desktop", log: osLog, type: .default)
                        }
                }
                if debug {
                        os_log("Will attempt to launch GUI installer for %{public}@", log: osLog, type: .info, desktopPath)
                } else {
                        os_log("Will attempt to launch GUI installer", log: osLog, type: .info)
                }
                var result: Bool
                if launchInstaller(package: desktopPath) == 0 {
                        os_log("Open command completed with success", log: osLog, type: .info)
                        result = true
                } else {
                        os_log("Open command completed with errors", log: osLog, type: .default)
                        result = false
                }
                removeTemporaryDirectory()
                return result
        }
}
