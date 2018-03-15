/*
 * File: NvidiaCloverSettings.swift
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

import Foundation
import os.log

class NvidiaCloverSettings: CloverSettings {
        
        enum Keys {
                case KernelAndKextPatches
                case KextsToPatch
                case Find
                case Replace
                case Comment
                case Name
                case Disabled
                case NvidiaWeb
                case RtVariables
                var string: String {
                        switch self {
                        case .KernelAndKextPatches:
                                return "KernelAndKextPatches"
                        case .KextsToPatch:
                                return "KextsToPatch"
                        case .Find:
                                return "Find"
                        case .Replace:
                                return "Replace"
                        case .Comment:
                                return "Comment"
                        case .Name:
                                return "Name"
                        case .Disabled:
                                return "Disabled"
                        case .NvidiaWeb:
                                return "NvidiaWeb"
                        case .RtVariables:
                                return "RtVariables"
                        }
                }
        }
        
        let startupWebPatch: [String: Any] = [Keys.Name.string: "NVDAStartupWeb", Keys.Find.string: Data.init(bytes: [0x4e, 0x56, 0x44, 0x41, 0x52, 0x65, 0x71, 0x75, 0x69, 0x72, 0x65, 0x64, 0x4f, 0x53, 0x00]), Keys.Replace.string: Data.init(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), Keys.Comment.string: "webdriver.sh: Disable NVIDIA Required OS", Keys.Disabled.string: false]
        
        private var _nvidiaWebIsEnabled: Bool = false
        private var _nvdaStartupPatchIsEnabled: Bool = false
        
        var nvidiaWebIsEnabled: Bool {
                get {
                        return _nvidiaWebIsEnabled
                }
                set {
                        if sync(leavingPartitionMounted: true) {
                                
                                if _nvidiaWebIsEnabled == newValue {
                                        
                                        os_log("NvidiaCloverSettings: _nvidiaWebIsEnabled is already %{public}@", newValue.description)
                                        
                                } else {
                                        
                                        if let runtimeVariables = dictionary?[Keys.RtVariables.string] as? NSMutableDictionary {
                                                switch newValue {
                                                case true:
                                                        runtimeVariables[Keys.NvidiaWeb.string] = true
                                                        if write() {
                                                                _nvidiaWebIsEnabled = newValue
                                                        }
                                                case false:
                                                        runtimeVariables.removeObject(forKey: Keys.NvidiaWeb.string)
                                                        if write() {
                                                                _nvidiaWebIsEnabled = newValue
                                                        }
                                                }
                                                
                                        } else if newValue == true {
                                                
                                                let runtimeVariables: [String : Any] = [Keys.NvidiaWeb.string : true]
                                                dictionary?.setObject(runtimeVariables, forKey: Keys.RtVariables.string as NSCopying)
                                                
                                                if write() {
                                                        _nvidiaWebIsEnabled = newValue
                                                }
                                        }
                                }
                        }
                }
        }
        
        var nvdaStartupPatchIsEnabled: Bool {
                get {
                        return _nvdaStartupPatchIsEnabled
                }
                set {
                        if sync(leavingPartitionMounted: true) {
                                
                                if _nvdaStartupPatchIsEnabled == newValue {
                                        
                                        os_log("NvidiaCloverSettings: _nvdaStartupPatchIsEnabled is already %{public}@", newValue.description)
                                        
                                } else {
                                        
                                        var patch = startupWebPatch
                                        patch[Keys.Disabled.string] = !newValue
                                        var kernelAndKextPatches: NSMutableDictionary?
                                        var kextsToPatch: NSMutableArray?
                                        
                                        if let dict = dictionary?[Keys.KernelAndKextPatches.string] as? NSMutableDictionary {
                                                if let array = dict[Keys.KextsToPatch.string] as? NSMutableArray {
                                                        kernelAndKextPatches = dict
                                                        kextsToPatch = array
                                                } else {
                                                        kernelAndKextPatches = dict
                                                        kextsToPatch = nil
                                                }
                                                
                                        } else {
                                                
                                                kernelAndKextPatches = nil
                                                kextsToPatch = nil
                                        }
                                        
                                        if kernelAndKextPatches == nil {
                                                
                                                /* Create new KernelAndKextPatches dict, new KextsToPatch array */
                                                
                                                kernelAndKextPatches = NSMutableDictionary.init()
                                                kextsToPatch = NSMutableArray.init(objects: patch)
                                                kernelAndKextPatches?.addEntries(from: [Keys.KextsToPatch.string: kextsToPatch!])
                                                dictionary?.addEntries(from: [Keys.KernelAndKextPatches.string: kernelAndKextPatches!])
                                                
                                        } else {
                                                
                                                if kextsToPatch == nil {
                                                        
                                                        /* Add new KextsToPatch array to existing KernelAndKextPatches dict */
                                                        
                                                        kextsToPatch = NSMutableArray.init(objects: patch)
                                                        kernelAndKextPatches?.addEntries(from: [Keys.KextsToPatch.string: kextsToPatch!])
                                                        
                                                } else {
                                                        
                                                        /* Merge into existing, try to remove duplicates */
                                                        
                                                        let duplicates: IndexSet? = kextsToPatch?.indexesOfObjects(options: [], passingTest: { (constraint, idx, stop) in
                                                                if let dict = constraint as? NSDictionary {
                                                                        let test: String? = dict[Keys.Comment.string] as? String
                                                                        if let commentString: String = test {
                                                                                if commentString.contains("webdriver.sh: ") {
                                                                                        return true
                                                                                }
                                                                        }
                                                                        if (dict[Keys.Find.string] as? Data == patch[Keys.Find.string] as? Data && dict[Keys.Name.string] as? String == patch[Keys.Name.string] as? String) {
                                                                                return true
                                                                        }
                                                                }
                                                                return false
                                                        })
                                                        
                                                        if duplicates != nil {
                                                                kextsToPatch?.removeObjects(at: duplicates!)
                                                        }
                                                        
                                                        /* Add the patch */
                                                        
                                                        kextsToPatch?.add(patch)
                                                }
                                        }
                                        
                                        if write() {
                                                _nvdaStartupPatchIsEnabled = newValue
                                        }
                                        
                                }
                        }
                }
        }
        
        override func sync(leavingPartitionMounted leaveMounted: Bool = false) -> Bool {
                
                os_log("NvidiaCloverSettings: Syncing")
                
                let syncResult = super.sync(leavingPartitionMounted: leaveMounted)
                if syncResult {
                        _nvidiaWebIsEnabled = false
                        _nvdaStartupPatchIsEnabled = false
                        
                        /* sync _nvidiaWebIsEnabled */
                        
                        if let runtimeVariables = dictionary?[Keys.RtVariables.string] as? NSDictionary {
                                let nvidiaWeb: Bool? = runtimeVariables[Keys.NvidiaWeb.string] as? Bool
                                if nvidiaWeb != nil, nvidiaWeb! == true {
                                        _nvidiaWebIsEnabled = true
                                }
                        }
                        
                        /* sync _nvdaStartupPatchIsEnabled */
                        
                        var enabledPatchesIndicies = IndexSet()
                        if let kernelAndKextPatches = dictionary?[Keys.KernelAndKextPatches.string] as? NSDictionary {
                                if let kextsToPatch = kernelAndKextPatches[Keys.KextsToPatch.string] as? NSArray {
                                        enabledPatchesIndicies = kextsToPatch.indexesOfObjects(options: [], passingTest: { (constraint, idx, stop) in
                                                if let test = constraint as? NSDictionary {
                                                        if (test[Keys.Find.string] as? Data == startupWebPatch[Keys.Find.string] as? Data && test[Keys.Name.string] as? String == startupWebPatch[Keys.Name.string] as? String && test[Keys.Disabled.string] as? Bool != Optional(Bool(true))) {
                                                                return true
                                                        }
                                                }
                                                return false
                                        })
                                }
                        }
                        
                        if enabledPatchesIndicies.count > 0 {
                                _nvdaStartupPatchIsEnabled = true
                        }
                        
                }
                
                return syncResult
        }
        
}
