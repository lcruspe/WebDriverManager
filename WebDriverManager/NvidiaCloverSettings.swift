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
        
        let nvdaStartupFind = Data.init(bytes: [0x4e, 0x56, 0x44, 0x41, 0x52, 0x65, 0x71, 0x75, 0x69, 0x72, 0x65, 0x64, 0x4f, 0x53, 0x00])
        let nvdaStartupReplace = Data.init(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        private var _nvidiaWebIsEnabled: Bool = false
        private var _nvdaStartupPatchIsEnabled: Bool = false
        
        var nvidiaWebIsEnabled: Bool {
                get {
                        return _nvidiaWebIsEnabled
                }
                set {
                        let syncResult = sync(leavingPartitionMounted: true)
                        if syncResult {
                                if _nvidiaWebIsEnabled == newValue {
                                        os_log("NvidiaCloverSettings: _nvidiaWebIsEnabled is already %{public}@", newValue.description)
                                } else {
                                        os_log("NvidiaCloverSettings: Not implemented: Set _nvidiaWebIsEnabled to %{public}@", newValue.description)
                                }
                                
                        }
                }
        }
        
        var nvdaStartupPatchIsEnabled: Bool {
                get {
                        return _nvdaStartupPatchIsEnabled
                }
                set {
                        let syncResult = sync(leavingPartitionMounted: true)
                        if syncResult {
                                if _nvdaStartupPatchIsEnabled == newValue {
                                        os_log("NvidiaCloverSettings: _nvdaStartupPatchIsEnabled is already %{public}@", newValue.description)
                                 } else {
                                        os_log("NvidiaCloverSettings: Not implemented: Set _nvdaStartupPatchIsEnabled to %{public}@", newValue.description)
                                }
                        }
                }
        }
        
        override func sync(leavingPartitionMounted leaveMounted: Bool = false) -> Bool {
                os_log("NvidiaCloverSettings: Syncing")
                let result = super.sync(leavingPartitionMounted: leaveMounted)
                if result {
                        _nvidiaWebIsEnabled = false
                        _nvdaStartupPatchIsEnabled = false
                        /* sync _nvidiaWebIsEnabled */
                        if let runtimeVariables = dictionary?["RtVariables"] as? NSDictionary {
                                let nvidiaWeb: Bool? = runtimeVariables["NvidiaWeb"] as? Bool
                                if nvidiaWeb != nil, nvidiaWeb! == true {
                                        _nvidiaWebIsEnabled = true
                                }
                        }
                        /* sync _nvdaStartupPatchIsEnabled */
                        var enabledPatchesIndicies = IndexSet()
                        if let kernelAndKextPatches = dictionary?["KernelAndKextPatches"] as? NSDictionary {
                                if let kextsToPatch = kernelAndKextPatches["KextsToPatch"] as? NSArray {
                                        enabledPatchesIndicies = kextsToPatch.indexesOfObjects(options: [], passingTest: { (constraint, idx, stop) in
                                                if let dict = constraint as? NSDictionary {
                                                        if (dict["Find"] as? Data == nvdaStartupFind && dict["Name"] as? String == "NVDAStartupWeb" && dict["Disabled"] as? Bool != Optional(Bool(true))) {
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
                return result
        }
        
}
