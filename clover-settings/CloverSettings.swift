/*
 * CloverSettings.swift
 * Copyright © vulgo 2018
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
 *
 */

import Foundation
import os.log

extension String {
        var lines: [String] {
                var result: [String] = []
                enumerateLines { line, _ in result.append(line) }
                return result
        }
}

class CloverSettings {
        
        let osLog = OSLog.init(subsystem: "org.vulgo.CloverSettings", category: "CloverSettings")
        var dictionary: NSMutableDictionary?
        var bootLogData: Data?
        var bootLog: String?
        var cloverVolumeUuid: String?
        var cloverPathComponents: [String]?
        var lastVolumeUrl: URL?
        var lastSettingsUrl: URL?
        var lastBsdName: String?
        var mountCalled: Bool = false
        
        private let session: DASession = DASessionCreate(kCFAllocatorDefault)!
        private let fileManager = FileManager()
        private var settingsFileName: String = "config"
        
        private var cloverVolumeUrl: URL? {
                if cloverBsdName != nil {
                        if let disk: DADisk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, lastBsdName!) {
                                if let diskDescription: [String: Any] = DADiskCopyDescription(disk) as? Dictionary {
                                        if let url = diskDescription["DAVolumePath"] as! URL? {
                                                lastVolumeUrl = url
                                                return url
                                        }
                                }
                        }
                }
                lastVolumeUrl = nil
                return nil
        }
        
        private var cloverBsdName: String? {
                if let uuidSearch: String = cloverVolumeUuid {
                        let ioMediaBSDClientMatches = RegistryEntry.init(iteratorFromMatchingDictionary: IOServiceMatching("IOMediaBSDClient"))
                        while true {
                                ioMediaBSDClientMatches.registryEntry = IOIteratorNext(ioMediaBSDClientMatches.iterator)
                                let ioMedia = RegistryEntry.init(parentOf: ioMediaBSDClientMatches.registryEntry)
                                if IORegistryEntryCopyPath(ioMedia.registryEntry, kIOServicePlane) == nil {
                                        break
                                }
                                let thisUuid = ioMedia.getStringValue(forProperty: "UUID")
                                if thisUuid == uuidSearch {
                                        let bsdName = ioMedia.getStringValue(forProperty: "BSD Name")
                                        lastBsdName = bsdName
                                        return bsdName
                                }
                        }
                }
                lastBsdName = nil
                return nil
        }
        
        private var cloverSettingsUrl: URL? {
                urlIsNil: if cloverVolumeUrl == nil {
                        /* Try to mount the partition */
                        for _ in 1...2 {
                                _mount(bsdName: cloverBsdName!)
                                if cloverVolumeUrl != nil {
                                        break urlIsNil
                                }
                                os_log("EFI partition is not mounted!", log: osLog, type: .default)
                                sleep(1)
                        }
                        os_log("Clover volume URL should no longer be nil", log: osLog, type: .default)
                        lastSettingsUrl = nil
                        return nil
                }
                let settingsUrl = appendTo(url: lastVolumeUrl!, directories: cloverPathComponents, fileName: settingsFileName, ext: "plist")
                guard fileManager.fileExists(atPath: settingsUrl.path) else {
                        os_log("Clover settings file not found", log: osLog, type: .default)
                        lastSettingsUrl = nil
                        return nil
                }
                lastSettingsUrl = settingsUrl
                return settingsUrl
        }
        
        func _unmount(bsdName: String) {
                _mount(bsdName: bsdName, unmount: true)
        }
        
        func _mount(bsdName: String, unmount: Bool = false) {
                if let disk: DADisk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, bsdName) {
                        if unmount {
                                DADiskUnmount(disk, 0, nil, nil)
                        } else {
                                mountCalled = true
                                DADiskMount(disk, nil, 0, {
                                        (disk: DADisk, dissenter: DADissenter?, context: UnsafeMutableRawPointer?) -> Void in
                                        if dissenter != nil {
                                                // to do: mount as root
                                        }
                                }, nil)
                        }
                }
        }
        
        private func appendTo(url base: URL, directories: [String]? = nil, fileName: String? = nil, ext: String? = nil) -> URL {
                var url: URL = base
                if directories != nil {
                        for directory: String in directories! {
                                url = url.appendingPathComponent(directory, isDirectory: true)
                        }
                }
                if let fileName: String = fileName {
                        url = url.appendingPathComponent(fileName)
                }
                if let ext: String = ext {
                        url = url.appendingPathExtension(ext)
                }
                return url
        }
        
        func write() -> Bool {
                if let settingsUrl = cloverSettingsUrl {
                        let backupUrl = appendTo(url: lastVolumeUrl!, directories: cloverPathComponents, fileName: settingsFileName, ext: "~plist")
                        var propertyList: Data
                        do {
                                propertyList = try PropertyListSerialization.data(fromPropertyList: dictionary!, format: .xml, options: 0)
                        } catch {
                                let errorDescription = error.localizedDescription
                                os_log("%@", log: osLog, type: .default, errorDescription)
                                os_log("Error serializing property list", log: osLog, type: .default)
                                return false
                        }
                        do {
                                if fileManager.fileExists(atPath: backupUrl.path) {
                                        try fileManager.removeItem(atPath: backupUrl.path)
                                }
                                try fileManager.copyItem(at: settingsUrl, to: backupUrl)
                                try propertyList.write(to: settingsUrl)
                        } catch let error as NSError {
                                let errorDescription = error.localizedDescription
                                os_log("%@", log: osLog, type: .default, errorDescription)
                                os_log("Error writing settings", log: osLog, type: .default)
                                return false
                        }
                        os_log("Wrote settings", log: osLog, type: .default)
                        return true
                } else {
                        os_log("Failed to write settings, cloverSettingsUrl is nil", log: osLog, type: .default)
                        return false
                }
        }
        
        func sync(leavingPartitionMounted leaveMounted: Bool = false) -> Bool {
                var result = false
                if let url = cloverSettingsUrl {
                        dictionary = NSMutableDictionary.init(contentsOf: url)
                        result = true
                } else {
                        os_log("Failed to obtain settings dictionary", log: osLog, type: .default)
                }
                if mountCalled && !leaveMounted {
                        mountCalled = false
                        _unmount(bsdName: lastBsdName!)
                }
                return result
        }
        
        init?(fileName: String? = nil, leavingPartitionMounted leaveMounted: Bool = false) {
                
                if let userFileName = fileName {
                        /* without extension e.g. "config" not "config.plist" */
                        settingsFileName = userFileName
                }
                
                /* Store booted Clover boot-log */
                
                let platform = RegistryEntry.init(fromPath: "IODeviceTree:/efi/platform")
                bootLogData = platform?.getDataValue(forProperty: "boot-log") as Data?
                
                guard bootLogData != nil else {
                        return nil
                }
                
                var bootLog: [String]
                var stringComponents: [String]?
                let bootLogString = NSString.init(data: bootLogData!, encoding: String.Encoding.utf8.rawValue)! as String
                bootLog = bootLogString.lines
                
                /* Store booted Clover partition UUID */
                
                for line in bootLog {
                        if line.contains("SelfDevicePath") {
                                stringComponents = line.split{$0 == ","}.map(String.init)
                                break
                        }
                }
                
                if stringComponents != nil {
                        for component in stringComponents! {
                                if let uuid = NSUUID.init(uuidString: component) {
                                        cloverVolumeUuid = uuid.uuidString
                                        break
                                }
                        }
                }
                
                /* Store booted Clover path components */
                
                stringComponents = nil
                
                for line in bootLog {
                        if line.contains("SelfDirPath") {
                                stringComponents = line.split{$0 == " "}.map(String.init)
                                break
                        }
                }
                
                if stringComponents != nil {
                        for component in stringComponents! {
                                if component.contains("\\") {
                                        let realDirectory = component.replacingOccurrences(of: "\\EFI\\BOOT", with: "\\EFI\\CLOVER")
                                        cloverPathComponents = realDirectory.split{$0 == "\\"}.map(String.init)
                                        break
                                }
                        }
                }
                
                /* Initialize settings dictionary */
                
                if sync(leavingPartitionMounted: leaveMounted) {
                        os_log("Initialized", log: osLog, type: .default)
                } else {
                        os_log("Failed to initialize", log: osLog, type: .default)
                        return nil
                }
        }
}
