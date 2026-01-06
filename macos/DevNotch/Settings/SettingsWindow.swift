//
//  SettingsWindow.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import Cocoa
import SwiftUI

class SettingsWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "DevNotch Settings"
        self.center()
        
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        self.contentView = hostingView
        
        self.isReleasedWhenClosed = false
    }
    
    static func show() {
        let settingsWindow = SettingsWindow()
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
