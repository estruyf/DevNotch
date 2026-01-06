//
//  DevNotchApp.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI

@main
struct DevNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NotchWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create and show notch window
        notchWindow = NotchWindow()
        notchWindow?.makeKeyAndOrderFront(nil)
        
        // Prevent app from terminating when window closes
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
