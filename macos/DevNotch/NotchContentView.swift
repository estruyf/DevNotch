//
//  NotchContentView.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI

struct NotchContentView: View {
    var onToggle: () -> Void
    @State private var isExpanded = false
    
    // Animation constants matching "Boring Notch" feel
    private let springAnimation = Animation.interactiveSpring(
        response: 0.35,
        dampingFraction: 0.75, // Slightly bouncy
        blendDuration: 0
    )
    
    // Geometry constants
    private var compactHeight: CGFloat {
        guard let screen = NSScreen.main else { return 32 }
        return screen.frame.height - screen.visibleFrame.maxY
    }
    private let compactWidth: CGFloat = 220
    private let expandedWidth: CGFloat = 400
    
    @State private var hoverTimer: Timer?
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Notch Container
            VStack(spacing: 0) {
                if isExpanded {
                    // Expanded Content
                    VStack(spacing: 0) {
                        NowPlayingView()
                            .frame(height: 64)
                            .padding(.top, 8)
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 8)
                        CopilotUsageView()
                            .frame(height: 40)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 16)
                    .transition(
                        .scale(scale: 0.8, anchor: .top)
                        .combined(with: .opacity)
                    )
                } else {
                    // Compact Content
                    CompactNowPlayingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                }
            }
            .frame(
                width: isExpanded ? expandedWidth : compactWidth,
                height: isExpanded ? 150 : compactHeight // Approximate expanded height
            )
            .background(Color.black.opacity(0.85))
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, // Match bottom radius or NotchDrop style
                bottomLeadingRadius: isExpanded ? 32 : 8,
                bottomTrailingRadius: isExpanded ? 32 : 8,
                topTrailingRadius: 0
            ))
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10) // Enhanced shadow
            .shadow(color: .black.opacity(0.2), radius: 5, y: 2) // Tighter shadow
            .contentShape(Rectangle()) // Capture taps
            .onTapGesture {
                if !isExpanded {
                    // Start Expansion:
                    // 1. Tell Window to resize (call onToggle)
                    // 2. Wait for Notification to start Animation
                    onToggle()
                } else {
                    // Do nothing on tap if expanded, or handle internal taps
                    // If we wanted to close on tap:
                    // toggleState(false)
                }
            }
            .onHover { hovering in
                isHovering = hovering
                if isExpanded {
                    if hovering {
                        // Mouse entered, cancel auto-close
                        hoverTimer?.invalidate()
                        hoverTimer = nil
                    } else {
                        // Mouse left, start auto-close timer
                        hoverTimer?.invalidate()
                        hoverTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                             toggleState(false)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Align everything to the top of the transparent window
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NotchExpandedStateChanged"))) { notif in
            if let expanded = notif.userInfo?["isExpanded"] as? Bool {
                // Update state from notification without triggering callback loop
                withAnimation(springAnimation) {
                    self.isExpanded = expanded
                }
            }
        }
    }
    
    private func toggleState(_ expanded: Bool) {
        guard isExpanded != expanded else { return }
        
        withAnimation(springAnimation) {
            self.isExpanded = expanded
        }
        
        // Only call onToggle (which flips window state) if we are driving the change
        onToggle()
    }
}
