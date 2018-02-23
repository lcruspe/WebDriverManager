/*
 * File: Nvram.swift
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

class Nvram {
        
        /* No GUID = Apple default GUID */
        
        let ioNvramForceSyncNowPropertyKey = "IONVRAM-FORCESYNCNOW-PROPERTY"
        let options = RegistryEntry(fromPath: "IODeviceTree:/options")
        
        func deleteVariable(key: String) {
                let _ = options.setStringValue(forProperty: kIONVRAMDeletePropertyKey, value: key)
        }

        func nvramSyncNow(withNamedVariable key: String, useForceSync: Bool = false) -> kern_return_t {
                var result: kern_return_t
                if (useForceSync) {
                        result = options.setStringValue(forProperty: ioNvramForceSyncNowPropertyKey, value: key)
                } else {
                        result = options.setStringValue(forProperty: kIONVRAMSyncNowPropertyKey, value: key)
                }
                if result != KERN_SUCCESS {
                        Log.log("Error syncing %{public}@", key)
                }
                return result
        }
}
