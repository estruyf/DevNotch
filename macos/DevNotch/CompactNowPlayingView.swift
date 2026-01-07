//
//  CompactNowPlayingView.swift
//  DevNotch
//
//  Created on 2026-01-06.
//

import SwiftUI

struct CompactNowPlayingView: View {
    @ObservedObject private var controller = MediaRemoteController.shared
    @ObservedObject private var copilot = CopilotClient.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // Left side: artwork + track if playing, Copilot icon if paused
            if let info = controller.nowPlayingInfo, info.isPlaying {
                if let data = info.artworkData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }

                Text("\(info.artistName) - \(info.trackName)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else if controller.nowPlayingInfo != nil && !controller.nowPlayingInfo!.isPlaying {
                // Music paused: show Copilot icon
                if let iconImage = ImageLoader.loadCopilotIcon() {
                    Image(nsImage: iconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                }
            } else {
                // No music: reserve minimal left space for consistent layout
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 18, height: 18)
            }

            Spacer()

            // If music is playing show waveform, if paused show usage dot
            if let info = controller.nowPlayingInfo, info.isPlaying {
                let waveColor = waveformColor(for: copilot.usagePercentage)
                WaveformView(color: waveColor)
                    .frame(width: 20, height: 12)
            } else if controller.nowPlayingInfo != nil && !controller.nowPlayingInfo!.isPlaying {
                // Music paused: show usage state dot
                let dotColor = waveformColor(for: copilot.usagePercentage)
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity)
    }
    
    // Determine waveform color based on Copilot usage percentage
    private func waveformColor(for percentage: Double?) -> Color {
        guard let p = percentage else { return Color.orange }
        // Green when high remaining (>60%), yellow when medium (20-60%), red when low (<20%)
        if p > 0.6 {
            return Color.green
        } else if p > 0.2 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
}

struct WaveformView: View {
    let color: Color
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 3, height: self.height(for: i))
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: phase
                    )
            }
        }
        .onAppear {
            phase = 1
        }
    }
    
    func height(for index: Int) -> CGFloat {
        // Randomize or pattern based on phase
        // Since phase is just a trigger, we use the fact that invalidation happens?
        // Actually, easiest way to animate height randomly in SwiftUI loop is tricky without individual state.
        // Let's use a known oscillating pattern.
        return phase == 0 ? 4 : CGFloat([6, 12, 8, 10][index])
    }
}

struct CompactNowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        CompactNowPlayingView()
            .frame(width: 220, height: 32)
            .background(Color.black)
    }
}
