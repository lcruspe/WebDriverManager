/*
 * RegistryEntry.swift
 * Copyright © 2017-2018 vulgo
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
import IOKit
import os.log

class RegistryEntry {
        
        var registryEntry = io_registry_entry_t()
        var iterator = io_iterator_t()
        let osLog = OSLog.init(subsystem: "org.vulgo.RegistryEntry", category: "RegistryEntry")
        
        enum typeId {
                static let number = CFNumberGetTypeID()
                static let string = CFStringGetTypeID()
                static let data = CFDataGetTypeID()
                static let bool = CFBooleanGetTypeID()
                static let dictionary = CFDictionaryGetTypeID()
        }
        
        init?(fromPath path: String) {
                registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, path)
                guard registryEntry != 0 else {
                        os_log("RegistryEntry: Error getting registry entry from path", log: osLog, type: .default)
                        return nil
                }
        }
	
        init(parentOf child: io_registry_entry_t) {
                var parent = io_registry_entry_t()
                IORegistryEntryGetParentEntry(child, kIOServicePlane, &parent)
                registryEntry = parent
        }
        
        init(fromMatchingDictionary dictionary: CFDictionary) {
                registryEntry = IOServiceGetMatchingService(kIOMasterPortDefault, dictionary)
        }
        
        init(iteratorFromMatchingDictionary dictionary: CFDictionary) {
                registryEntry = io_registry_entry_t(IOServiceGetMatchingServices(kIOMasterPortDefault, dictionary, &iterator))
        }
        
        /*
         *  Get properties
         */
        
        private func getValue(forProperty key: String, type: CFTypeID) -> Any? {
                if let value: CFTypeRef = IORegistryEntryCreateCFProperty(registryEntry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() {
                        let valueType = CFGetTypeID(value)
                        guard valueType == type else {
                                os_log("CFType mismatch", log: osLog, type: .default)
                                return nil
                        }
                        return value
                }
                return nil
        }
        
        func getIntValue(forProperty key: String) -> Int? {
                guard let int = getValue(forProperty: key, type: typeId.number) as? Int else {
                        return nil
                }
                return int
        }
        
        func getStringValue(forProperty key: String) -> String? {
                guard let string = getValue(forProperty: key, type: typeId.string) as? String else {
                        return nil
                }
                return string
        }
        
        func getDataValue(forProperty key: String) -> Data? {
                guard let data = getValue(forProperty: key, type: typeId.data) as? Data else {
                        return nil
                }
                return data
        }
        
        func getBoolValue(forProperty key: String) -> Bool? {
                guard let bool = getValue(forProperty: key, type: typeId.bool) as? Bool else {
                        return nil
                }
                return bool
        }
        
        func getDictionary(forProperty key: String) -> Dictionary<String, Any>? {
                guard let dictionary = getValue(forProperty: key, type: typeId.dictionary) as? Dictionary<String, Any> else {
                        return nil
                }
                return dictionary
        }
	
        /*
         *  Set properties
         */
        
        private func setValue(forProperty key: String, value: Any, type: CFTypeID) -> kern_return_t {
                var result: kern_return_t
                switch type {
                case typeId.number:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFNumber)
                case typeId.string:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFString)
                case typeId.data:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFData)
                case typeId.bool:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFBoolean)
                case typeId.dictionary:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFDictionary)
                default:
                        result = -1
                        os_log("CFDate, CFArray, are not implemented", log: osLog, type: .default)
                }
                if result != KERN_SUCCESS {
                        os_log("Error setting value for property %{public}@", log: osLog, type: .default, key)
                        os_log("IORegistryEntrySetCFProperty kern_return_t was %{public}X", log: osLog, type: .default, result)
                }
                return result
        }
        
        func setIntValue(forProperty key: String, value: Int) -> kern_return_t {
                let type = typeId.number
                let result = setValue(forProperty: key, value: value as CFNumber, type: type)
                return result
        }
        
        func setStringValue(forProperty key: String, value: String) -> kern_return_t {
                let type = typeId.string
                let result = setValue(forProperty: key, value: value as CFString, type: type)
                return result
        }
        
        func setDataValue(forProperty key: String, value: Data) -> kern_return_t {
                let type = typeId.data
                let result = setValue(forProperty: key, value: value as CFData, type: type)
                return result
        }
        
        func setBoolValue(forKey key: String, value: Bool) -> kern_return_t {
                let type = typeId.bool
                let result = setValue(forProperty: key, value: value as CFBoolean, type: type)
                return result
        }
        
        func setDictionary(forKey key: String, value: Dictionary<String, Any>) -> kern_return_t {
                let type = typeId.dictionary
                let result = setValue(forProperty: key, value: value as CFDictionary, type: type)
                return result
        }
        
}

