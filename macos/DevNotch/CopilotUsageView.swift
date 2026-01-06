//
//  CopilotUsageView.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI

struct CopilotUsageView: View {
    @State private var percentage: Double = 0.0
    
    @StateObject private var client = CopilotClient.shared
    @State private var showDeviceInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Copilot")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if let p = client.usagePercentage {
                    Text(String(format: "%.0f%%", p * 100))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text("—")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            ProgressView(value: client.usagePercentage ?? 0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            HStack {
                if client.isAuthenticated {
                    Button("Refresh") { client.fetchUsage() }
                    Button("Sign out") { client.signOut() }
                } else {
                    Button("Sign in") {
                        client.startDeviceFlow()
                        showDeviceInfo = true
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .onAppear {
            if client.isAuthenticated { client.fetchUsage() }
        }
        .sheet(isPresented: $showDeviceInfo) {
            VStack(spacing: 12) {
                if let url = client.verificationUri {
                    Text("Open this URL in your browser and enter the code:")
                    Text(url)
                        .underline()
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                }
                if let code = client.userCode {
                    Text(code)
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .padding()
                }
                if client.polling {
                    Text("Waiting for authorization...")
                }
                Button("Close") { showDeviceInfo = false }
            }
            .padding()
            .frame(width: 420, height: 260)
                }
            }
        }

struct CopilotUsageView_Previews: PreviewProvider {
    static var previews: some View {
        CopilotUsageView()
            .frame(width: 360)
            .background(Color.black.opacity(0.85))
    }
}
