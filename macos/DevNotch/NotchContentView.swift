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
    private let compactWidth: CGFloat = 350
    private let expandedWidth: CGFloat = 500
    @State private var manualToken: String = ""
    private var expandedHeight: CGFloat {
        return 150
    }
    
    // ... rest of state
    @State private var hoverTimer: Timer?
    @State private var isHovering = false
    @ObservedObject private var copilotClient = CopilotClient.shared
    
    // Aesthetic constants
    private let spacing: CGFloat = 16
    private var notchCornerRadius: CGFloat { isExpanded ? 32 : 10 }
    
    var body: some View {
        ZStack(alignment: .top) {
            // The Notion Background Shape
            notch
                .contentShape(Rectangle()) // Capture taps on the shape
                .onTapGesture {
                    if !isExpanded {
                        onToggle()
                    }
                }
            
            // The Content
             VStack(spacing: 0) {
                if isExpanded {
                    // Expanded Content
                    VStack(spacing: 0) {
                        NowPlayingView()
                            .frame(height: 64)
                            .padding(.top, 8)
                        Divider()
                            .background(Color.black.opacity(0.1))
                            .padding(.vertical, 8)
                        CopilotUsageView()
                            .frame(height: 40)
                            .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 16)
                    // Fade in content
                    .transition(
                        .scale(scale: 0.9, anchor: .top)
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
                height: isExpanded ? expandedHeight : compactHeight
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onHover { hovering in
            isHovering = hovering
            if isExpanded {
                if hovering {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                         toggleState(false)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NotchExpandedStateChanged"))) { notif in
            if let expanded = notif.userInfo?["isExpanded"] as? Bool {
                withAnimation(springAnimation) {
                    self.isExpanded = expanded
                }
            }
        }
        .onReceive(copilotClient.$isAuthenticated) { auth in
            if auth, let token = copilotClient.token {
                self.manualToken = token
            }
        }
    }
    
    // MARK: - Visual Components
    
    private var currentNotchSize: CGSize {
        CGSize(
            width: isExpanded ? expandedWidth : compactWidth,
            height: isExpanded ? expandedHeight : compactHeight
        )
    }

    var notch: some View {
        Rectangle()
            .foregroundStyle(Color.black.opacity(0.90))
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: currentNotchSize.width + notchCornerRadius * 2,
                height: currentNotchSize.height
            )
            .shadow(
                color: .black.opacity(isExpanded ? 0.3 : 0),
                radius: 16,
                y: 5
            )
    }

    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: currentNotchSize.width,
                height: currentNotchSize.height
            )
            .clipShape(.rect(
                bottomLeadingRadius: notchCornerRadius,
                bottomTrailingRadius: notchCornerRadius
            ))
            .overlay {
                // Top Right "Liquid" Corner
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + spacing,
                            height: notchCornerRadius + spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchCornerRadius - spacing + 0.5, y: -0.5)
            }
            .overlay {
                // Top Left "Liquid" Corner
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + spacing,
                            height: notchCornerRadius + spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchCornerRadius + spacing - 0.5, y: -0.5)
            }
    }
    
    private func toggleState(_ expanded: Bool) {
        guard isExpanded != expanded else { return }
        
        withAnimation(springAnimation) {
            self.isExpanded = expanded
        }
        onToggle()
    }
    
    // MARK: - Overlays
    
    var deviceInfoOverlay: some View {
        VStack(spacing: 12) {
             Text("GitHub Copilot Usage")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("Enter your GitHub Personal Access Token or use the GitHub login")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if copilotClient.polling {
                VStack(spacing: 8) {
                     if let code = copilotClient.userCode {
                        Text(code)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .onTapGesture {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(code, forType: .string)
                            }
                        Text("(Code copied on click)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    if let url = copilotClient.verificationUri {
                         Button("Open Auth URL") {
                            if let u = URL(string: url) {
                                NSWorkspace.shared.open(u)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                        Text("Waiting for authorization...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            } else {
                Button(action: {
                   copilotClient.startDeviceFlow()
                }) {
                     HStack {
                        // GitHub Icon Key placeholder
                        Image(systemName: "key.fill")
                            .foregroundColor(.yellow)
                        Text("Sign in with GitHub Copilot")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.15, green: 0.17, blue: 0.20))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                if let error = copilotClient.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                    Text("or enter token manually").font(.caption).foregroundColor(.gray)
                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                }
                .padding(.vertical, 8)
                
                SecureField("ghp_...", text: $manualToken)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 1))
                
                Button(action: {
                    manualToken = ""
                }) {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if !manualToken.isEmpty {
                        copilotClient.manualTokenAuth(manualToken)
                        manualToken = ""
                    }
                }) {
                    Text("Save Token")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue) // Approximate color
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: expandedWidth, height: expandedHeight)
    }

}
