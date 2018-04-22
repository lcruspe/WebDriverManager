/*
 * Credit: Pavo-IM https://github.com/Pavo-IM/NvidiaWebDriverRepackager
 *
 * File: Liberator.swift
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

class Liberator {

        let osLog = OSLog.init(subsystem: "org.vulgo.WebDriverManager", category: "Liberator")
        let distribution: URL
        let fileManager = FileManager()
        
        init(_ url: URL) {
                distribution = url
        }

        func liberate() -> (String, String)? {
                
                var prefPaneId = "NVPrefPane"
                
                if !fileManager.fileExists(atPath: distribution.path) {
                        os_log("XML document not found", log: osLog, type: .default)
                        return nil
                }
                
                var document: XMLDocument?
                do {
                        document = try XMLDocument.init(contentsOf: distribution, options: XMLNode.Options.documentTidyXML)
                } catch {
                        os_log("Error parsing XML document", log: osLog, type: .default)
                        return nil
                }
                
                if document == nil {
                        os_log("XML document should no longer be nil", log: osLog, type: .default)
                        return nil
                }
                
                var xml: String = ""
                var objects: [Any] = []
                
                func xQueryResult(_ query: String) -> Any? {
                        do {
                                objects = try document!.objects(forXQuery: query)
                                if objects.count > 0 {
                                        return objects[0]
                                }
                                return nil
                        } catch {
                                return nil
                        }
                }
                
                func getDriverComponentDir() -> String? {
                        if let element = xQueryResult("for $x in /installer-gui-script/choice/pkg-ref where $x/@id='NV' return $x") as? XMLElement {
                                return element.stringValue?.replacingOccurrences(of: "#", with: "")
                        }
                        return nil
                }
                
                func getPackageTitle() -> String? {
                        if let element = xQueryResult("//title") as? XMLElement {
                                return element.stringValue
                        }
                        return nil
                }
                
                func getVersion() -> String? {
                        if let version = xQueryResult("for $x in //product return data($x/@version)") as? String {
                                return version
                        }
                        return nil
                }
                
                let name = getDriverComponentDir()
                let title = getPackageTitle()
                let version = getVersion()
                
                if name == nil {
                        os_log("Name should no longer be nil", log: osLog, type: .default)
                        return nil
                }
                
                if title == nil {
                        os_log("Title should no longer be nil", log: osLog, type: .default)
                        return nil
                }
                
                if version == nil {
                        os_log("Version should no longer be nil", log: osLog, type: .default)
                        return nil
                }
                
                xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                xml += "<installer-gui-script minSpecVersion=\"2\">"
                xml += "<title>\(title!)</title>"
                xml += "<options customize=\"never\" allow-external-scripts=\"false\" rootVolumeOnly=\"true\"/>"
                xml += "<background file=\"background.png\" scaling=\"none\" alignment=\"center\"/>"
                xml += "<welcome file=\"Welcome.rtf\"/>"
                xml += "<choices-outline>"
                xml += "<line choice=\"manual\"/>"
                xml += "</choices-outline>"
                xml += "<choice id=\"manual\" title=\"\(title!)\" description=\"NVIDIA driver components\">"
                xml += "<pkg-ref id=\"NV\" auth=\"Root\" onConclusion=\"none\">#\(name!)</pkg-ref>"
                xml += "</choice>"
                xml += "<pkg-ref id=\"NV\" packageIdentifier=\"com.nvidia.web-driver\"></pkg-ref>"
                xml += "<product id=\"com.nvidia.combo-pkg\" version=\"\(version!)\"/>"
                xml += "</installer-gui-script>"
                
                do {
                        document = try XMLDocument.init(xmlString: xml, options: XMLNode.Options.documentTidyXML)
                } catch {
                        os_log("Error parsing XML string", log: osLog, type: .default)
                        return nil
                }
                
                let data = document?.xmlData(options: XMLNode.Options.nodePrettyPrint)
                
                do  {
                        try data?.write(to: distribution)
                } catch {
                        os_log("Error writing xml", log: osLog, type: .default)
                        return nil
                }
                
                os_log("Wrote XML", log: osLog, type: .default)
                return (name!, version!)
        }
}
