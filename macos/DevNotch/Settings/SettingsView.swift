//
//  SettingsView.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @StateObject private var copilotClient = CopilotClient.shared
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var manualTokenInput: String = ""
    @State private var showManualTokenInput = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // General Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("General")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Divider()
                        
                        Toggle(isOn: $launchAtLogin) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Launch at Login")
                                    .font(.body)
                                Text("Automatically start DevNotch when you log in")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin) { newValue in
                            setLaunchAtLogin(enabled: newValue)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // GitHub Copilot Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("GitHub Copilot")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Divider()
                        
                        if let error = copilotClient.lastError {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if copilotClient.isAuthenticated {
                            authenticatedView
                        } else if let userCode = copilotClient.userCode, let verificationUri = copilotClient.verificationUri {
                            deviceFlowView(userCode: userCode, verificationUri: verificationUri)
                        } else {
                            unauthenticatedView
                        }
                        
                        // Manual Token Section
                        if !copilotClient.isAuthenticated {
                            Divider()
                            manualTokenView
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DevNotch")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("A utility to display media playback and GitHub Copilot usage in your notch")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private var authenticatedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Signed In")
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            if let username = copilotClient.username {
                Text("@\(username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
            
            Button(action: {
                copilotClient.signOut()
            }) {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.top, 8)
        }
    }
    
    private func deviceFlowView(userCode: String, verificationUri: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow these steps to sign in:")
                .font(.body)
            
            HStack(alignment: .top) {
                Text("1.")
                Text("Copy this code: ")
                Text(userCode)
                    .font(.monospaced(.body)())
                    .fontWeight(.bold)
                    .textSelection(.enabled)
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(userCode, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy code")
            }
            
            HStack(alignment: .top) {
                Text("2.")
                Text("Open the activation page:")
                Link(verificationUri, destination: URL(string: verificationUri)!)
            }
            
            HStack(alignment: .top) {
                Text("3.")
                Text("Paste the code and authorize.")
            }
            
            HStack {
                Button(action: {
                    if let url = URL(string: verificationUri) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Open Activation Page")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    copilotClient.resetAuthFlow()
                }) {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
    }
    
    private var unauthenticatedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .foregroundColor(.orange)
                Text("Not Signed In")
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Text("Sign in to view your GitHub Copilot usage statistics")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 24)
            
            Button(action: {
                copilotClient.startDeviceFlow()
            }) {
                Text("Sign In with GitHub")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
    }
    
    private var manualTokenView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    showManualTokenInput.toggle()
                }
            }) {
                HStack {
                    Text("Manual Token Entry")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: showManualTokenInput ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.borderless)
            
            if showManualTokenInput {
                Text("If the automated sign-in fails, paste your GitHub Copilot token here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Enter token (ghu_...)", text: $manualTokenInput)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    copilotClient.manualTokenAuth(manualTokenInput)
                    manualTokenInput = ""
                }) {
                    Text("Save Token")
                }
                .disabled(manualTokenInput.isEmpty)
            }
        }
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            // Fallback for older macOS versions
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.eliostruyf.devnotch"
            SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 500, height: 400)
}
