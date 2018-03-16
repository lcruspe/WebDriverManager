/*
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
        
        var status: Int?
        let fileManager = FileManager()
        
        init?(_ url: URL) {
                let result: Int = liberate(url: url)
                status = result
                if result < 0 {
                        return nil
                }
        }
        
        deinit {
                if let status = status {
                        os_log("Liberator: deinit with status %{public}@", String(status))
                } else {
                        os_log("Liberator: deinit with status nil")
                }
        }

        private func liberate(url: URL) -> Int {
                
                var status = 0
                var prefPaneId = "NVPrefPane"
                
                if !fileManager.fileExists(atPath: url.path) {
                        os_log("Liberator: XML document not found")
                        return -1
                }
                
                var document: XMLDocument?
                do {
                        document = try XMLDocument.init(contentsOf: url, options: XMLNode.Options.documentTidyXML)
                } catch {
                        os_log("Liberator: error parsing XML document")
                        return -1
                }
                
                if document == nil {
                        os_log("Liberator: XML document should no longer be nil")
                        return -1
                }
                
                var xml: String = ""
                var objects: [Any] = []
                
                func append(_ objects: [Any]) {
                        if objects.count == 0 {
                                os_log("Liberator: append was called on an empty array")
                        }
                        for object in objects {
                                if let e = object as? XMLElement {
                                        xml += e.canonicalXMLStringPreservingComments(false)
                                }
                        }
                }
                
                func query(_ query: String) {
                        do {
                                objects = try document!.objects(forXQuery: query)
                                if query == "//choice" {
                                        if let e = objects[0] as? XMLElement {
                                                var pp: Int?
                                                if let childNodes = e.children {
                                                        for i in 0..<childNodes.count {
                                                                let xml = childNodes[i].canonicalXMLStringPreservingComments(false)
                                                                if xml.contains("id=\"\(prefPaneId)\"") {
                                                                        pp = i
                                                                        break
                                                                }
                                                        }
                                                }
                                                if pp == nil {
                                                        pp = 1
                                                }
                                                e.removeChild(at: pp!)
                                                append([e])
                                        }
                                } else {
                                        append(objects)
                                }
                        } catch {
                                os_log("Liberator: xquery error (%{public}@)", query)
                                status = 67
                        }
                }
                
                xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?><installer-gui-script minSpecVersion=\"2\">"
                query("//title")
                query("//options")
                query("//background")
                query("//welcome")
                query("//license")
                query("for $x in //pkg-ref where $x/@id!='\(prefPaneId)' return $x")
                query("//choices-outline")
                query("//choice")
                query("//product")
                xml += "</installer-gui-script>"
                
                do {
                        document = try XMLDocument.init(xmlString: xml, options: XMLNode.Options.documentTidyXML)
                } catch {
                        os_log("Liberator: error parsing XML string")
                        return -1
                }
                
                let data = document?.xmlData(options: XMLNode.Options.nodePrettyPrint)
                
                do  {
                        try data?.write(to: url)
                } catch {
                        os_log("Liberator: error writing xml")
                        return -1
                }
                os_log("Liberator: wrote XML")
                return status
        }
}
