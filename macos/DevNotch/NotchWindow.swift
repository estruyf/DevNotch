//
//  NotchWindow.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import Cocoa
import SwiftUI

class NotchWindow: NSPanel {
    private var hostingView: NSHostingView<NotchContentView>?
    private var isExpanded = false
    
    private var compactHeight: CGFloat {
        guard let screen = NSScreen.main else { return 32 }
        return screen.frame.height - screen.visibleFrame.maxY
    }
    private let compactWidth: CGFloat = 220
    private let expandedHeight: CGFloat = 300 // Max allowed
    
    init() {
        // Calculate position at top center of screen
        guard let screen = NSScreen.main else {
            fatalError("No main screen found")
        }
        
        // Start with COMPACT size to allow clicks-through initially
        let screenFrame = screen.frame
        let currentCompactHeight = screen.frame.height - screen.visibleFrame.maxY
        let xPosition = screenFrame.minX + (screenFrame.width - compactWidth) / 2
        
        let initialRect = NSRect(
            x: xPosition,
            y: screenFrame.maxY - currentCompactHeight,
            width: compactWidth,
            height: currentCompactHeight
        )
        
        super.init(
            contentRect: initialRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Panel configuration
        self.level = .mainMenu + 1
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovable = false
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = false
        
        setupContentView()
        setupGlobalClickMonitor()
    }
    
    private func setupContentView() {
        let contentView = NotchContentView(
            onToggle: { [weak self] in
                self?.toggleExpanded()
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        self.contentView = hostingView
        self.hostingView = hostingView
    }
    
    private var globalClickMonitor: Any?
    private func setupGlobalClickMonitor() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self, self.isExpanded else { return }
            
            // We need to check if the click is outside the *visual* notch area, not the full clear window
            // Since we don't know the exact SwiftUI visual frame here easily without passing it back,
            // we will approximate or ideally handle this in SwiftUI. 
            // However, a simple approximation: if mouse is outside our max window, it's definitely outside.
            // If it's inside our max window but outside the expanded visual area, it's also a close.
            
            // For now, let's trust the SwiftUI tap handler for "inside" clicks and use this for "definitely outside"
            // Actually, since the window is large and transparent, clicks on the transparent part pass through IF ignoresMouseEvents is handled right,
            // but NSPanel captures them. To act like a "menu", checking screen location is safer.
            
            let mouseLocation = NSEvent.mouseLocation
            // If the click is not in our window's rect, close it.
            if !self.frame.contains(mouseLocation) {
                 DispatchQueue.main.async {
                    self.setExpanded(false)
                }
            }
        }
    }

    deinit {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func toggleExpanded() {
        setExpanded(!isExpanded)
    }
    
    private func setExpanded(_ expanded: Bool) {
        // Toggle logic with instant window resize but delayed shrink
        guard isExpanded != expanded else { return }
        isExpanded = expanded
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        if expanded {
            // MAXIMIZE WINDOW INSTANTLY
            // Center large frame
            let maxWidth: CGFloat = 500
            let maxHeight: CGFloat = 300
            let xPosition = screenFrame.minX + (screenFrame.width - maxWidth) / 2
            let largeFrame = NSRect(
                x: xPosition,
                y: screenFrame.maxY - maxHeight,
                width: maxWidth,
                height: maxHeight
            )
            self.setFrame(largeFrame, display: true)
            
            // Notify SwiftUI to animate content filling it
            NotificationCenter.default.post(
                name: NSNotification.Name("NotchExpandedStateChanged"),
                object: nil,
                userInfo: ["isExpanded": true]
            )
        } else {
            // NOTIFY SWIFTUI TO SHRINK FIRST
            NotificationCenter.default.post(
                name: NSNotification.Name("NotchExpandedStateChanged"),
                object: nil,
                userInfo: ["isExpanded": false]
            )
            
            // DELAY WINDOW SHRINK to allow animation to finish
            // Match SwiftUI animation duration ~0.35s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self, !self.isExpanded else { return }
                
                let compactH = self.compactHeight
                let compactW: CGFloat = 220
                let xPos = screenFrame.minX + (screenFrame.width - compactW) / 2
                let compactFrame = NSRect(
                    x: xPos,
                    y: screenFrame.maxY - compactH,
                    width: compactW,
                    height: compactH
                )
                self.setFrame(compactFrame, display: true)
            }
        }
    }
}
