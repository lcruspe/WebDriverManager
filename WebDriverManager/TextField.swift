/*
 * File: TextField.swift
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

class TextField: NSTextField {
        
        private let command: UInt = NSEvent.ModifierFlags.command.rawValue
        private let commandShift: UInt = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
        
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
                if event.type == NSEvent.EventType.keyDown {
                        let modifierFlags: UInt = event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
                        switch (modifierFlags, event.keyCode) {
                        case (command, 0):
                                return NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self)
                        case (command, 6):
                                return NSApp.sendAction(Selector(("undo:")), to: nil, from: self)
                        case (command, 7):
                                return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
                        case (command, 8):
                                return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
                        case (command, 9):
                                return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
                        case (commandShift, 6):
                                return NSApp.sendAction(Selector(("redo:")), to: nil, from: self)
                        default:
                                break
                        }
                }
                return super.performKeyEquivalent(with: event)
        }
}
