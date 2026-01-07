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
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = ImageLoader.loadCopilotIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text("GitHub Copilot Usage")
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
                    HoverButton(icon: "arrow.clockwise", iconColor: .white) {
                        client.fetchUsage()
                    }
                    
                    HoverButton(icon: "power", iconColor: .white) {
                        client.signOut()
                    }
                } else {
                    HoverButton(icon: "gearshape.fill", iconColor: .white) {
                        SettingsWindow.show()
                    }
                }
                Spacer()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
        .onAppear {
            // Check authentication status on first appearance
            // This is when keychain access will be requested if needed
            client.checkAuthenticationStatus()
        }
    }
}

struct CopilotUsageView_Previews: PreviewProvider {
    static var previews: some View {
        CopilotUsageView()
            .frame(width: 360)
            .background(Color.black)
    }
}
