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
    private var currentScreen: NSScreen?
    private var globalMouseMonitor: Any?
    
    private var compactHeight: CGFloat {
        guard let screen = currentScreen ?? NSScreen.main else { return 32 }
        return screen.frame.height - screen.visibleFrame.maxY
    }
    private let compactWidth: CGFloat = 220
    private let expandedHeight: CGFloat = 300 // Max allowed
    
    init() {
        // Calculate position at top center of screen
        guard let screen = NSScreen.main else {
            fatalError("No main screen found")
        }
        
        currentScreen = screen
        
        // Start with COMPACT size to allow clicks-through initially
        let screenFrame = screen.frame
        let currentCompactHeight = screen.frame.height - screen.visibleFrame.maxY
        // Width must account for visual rounded corners (220 content + 10 radius * 2 = 240)
        let visualCompactWidth: CGFloat = 240
        let xPosition = screenFrame.minX + (screenFrame.width - visualCompactWidth) / 2
        
        let initialRect = NSRect(
            x: xPosition,
            y: screenFrame.maxY - currentCompactHeight,
            width: visualCompactWidth,
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
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .transient]
        self.isMovable = false
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = false
        
        setupContentView()
        setupGlobalClickMonitor()
        setupGlobalMouseClickTracking()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    private func setupContentView() {
        let contentView = NotchContentView(
            onToggle: { [weak self] in
                self?.toggleExpanded()
            }
        )
        
        let hostingView = NotchHostingView(rootView: contentView)
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        self.contentView = hostingView
        self.hostingView = hostingView
    }
    
    private func setupGlobalMouseClickTracking() {
        // Monitor for screen parameter changes (resolution, arrangement, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Monitor global mouse clicks to detect when user clicks on a different screen
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleGlobalMouseClick(event)
        }
        
        // Also monitor local clicks (clicks on our own window)
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleGlobalMouseClick(event)
            return event
        }
    }
    
    private func handleGlobalMouseClick(_ event: NSEvent) {
        let clickLocation = NSEvent.mouseLocation
        
        // Find which screen the click occurred on
        guard let clickedScreen = NSScreen.screens.first(where: { $0.frame.contains(clickLocation) }) else {
            return
        }
        
        // Only update if we've clicked on a different screen
        if currentScreen != clickedScreen {
            currentScreen = clickedScreen
            updateWindowPosition()
        }
    }
    
    @objc private func screenParametersChanged() {
        // Screen configuration changed, update position on current screen
        updateWindowPosition()
    }
    
    private func updateWindowPosition() {
        guard let screen = currentScreen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        
        if isExpanded {
            // Update expanded position
            let maxWidth: CGFloat = 600
            let maxHeight: CGFloat = 300
            let xPosition = screenFrame.minX + (screenFrame.width - maxWidth) / 2
            let largeFrame = NSRect(
                x: xPosition,
                y: screenFrame.maxY - maxHeight,
                width: maxWidth,
                height: maxHeight
            )
            self.setFrame(largeFrame, display: true, animate: true)
        } else {
            // Update compact position
            let compactH = screen.frame.height - screen.visibleFrame.maxY
            let compactW: CGFloat = 370
            let xPos = screenFrame.minX + (screenFrame.width - compactW) / 2
            let compactFrame = NSRect(
                x: xPos,
                y: screenFrame.maxY - compactH,
                width: compactW,
                height: compactH
            )
            self.setFrame(compactFrame, display: true, animate: true)
        }
    }
    
    private var globalClickMonitor: Any?
    private func setupGlobalClickMonitor() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self, self.isExpanded else { return }
            
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
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NotificationCenter.default.removeObserver(self)
    }

    private func toggleExpanded() {
        setExpanded(!isExpanded)
    }
    
    private func setExpanded(_ expanded: Bool) {
        // Toggle logic with instant window resize but delayed shrink
        guard isExpanded != expanded else { return }
        isExpanded = expanded
        
        guard let screen = currentScreen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        
        if expanded {
            // MAXIMIZE WINDOW INSTANTLY
            // Center large frame
            let maxWidth: CGFloat = 600
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
                
                let compactH = screen.frame.height - screen.visibleFrame.maxY
                // Width must account for visual rounded corners (220 content + 10 radius * 2 = 240)
                let compactW: CGFloat = 370
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

class NotchHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func rightMouseDown(with event: NSEvent) {
        showContextMenu(with: event)
    }
    
    private func showContextMenu(with event: NSEvent) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit DevNotch", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    
    @objc private func openSettings() {
        SettingsWindow.show()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
