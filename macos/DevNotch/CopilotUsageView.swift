//
//  CopilotUsageView.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI

struct CopilotUsageView: View {
    @State private var percentage: Double = 0.0

    @ObservedObject private var client = CopilotClient.shared
    @Binding var showDeviceInfo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Copilot")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if let rem = client.copilotRemaining, let tot = client.copilotTotal {
                    Text("\(rem)/\(tot)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                } else if let p = client.usagePercentage {
                    // fallback to percentage if counts unknown
                    Text(String(format: "%.0f%%", p * 100))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text("—")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Larger progress bar that counts down (remaining/total)
            ProgressView(value: client.usagePercentage ?? 0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack(spacing: 8) {
                if client.isAuthenticated {
                    Button("Refresh") { client.fetchUsage() }
                    Button("Sign out") { client.signOut() }
                } else {
                    Button("Sign in") {
                        // Just show the overlay, don't start flow yet
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
    }
}

struct CopilotUsageView_Previews: PreviewProvider {
    static var previews: some View {
        CopilotUsageView(showDeviceInfo: .constant(false))
            .frame(width: 360)
            .background(Color.black.opacity(0.85))
    }
}
