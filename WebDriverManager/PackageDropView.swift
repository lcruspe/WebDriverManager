/*
 * File: PackageDropView.swift
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

class PackageDropView: NSVisualEffectView {
        
        @IBOutlet weak var dropLabelTextField: NSTextField!
        
        let defaultMaterial = NSVisualEffectView.Material.light
        let activeMaterial = NSVisualEffectView.Material.selection
        
        required init?(coder decoder: NSCoder) {
                super.init(coder: decoder)
                registerForDraggedTypes([.fileURL])
                material = defaultMaterial
        }
        
        var isActive = false {
                didSet {
                        if isActive {
                                material = activeMaterial
                                dropLabelTextField.alphaValue = 0.32
                        } else {
                                material = defaultMaterial
                                dropLabelTextField.alphaValue = 1.0
                        }
                }
        }
        
        func isValid(draggingInfo: NSDraggingInfo) -> Bool {
                let pasteBoard = draggingInfo.draggingPasteboard()
                if pasteBoard.propertyList(forType: .fileURL) != nil {
                        return true
                } else {
                        return false
                }
        }
        
        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
                if isValid(draggingInfo: sender) {
                        isActive = true
                        return NSDragOperation.copy
                } else {
                        isActive = false
                        return NSDragOperation()
                }
        }
        
        override func draggingExited(_ sender: NSDraggingInfo?) {
                isActive = false
        }
        
        override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
                return isValid(draggingInfo: sender)
        }
        
        override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
                isActive = false
                let pasteBoard = draggingInfo.draggingPasteboard()
                if let fileUrl = NSURL.init(from: pasteBoard) {
                        Packager.shared.packageUrl = fileUrl as URL
                        return true
                }
                return false
        }
        
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.keyEquivalent(with: event)
                }
                return false
        }
        
}
