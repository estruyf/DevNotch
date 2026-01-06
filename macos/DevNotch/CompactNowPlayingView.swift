//
//  CompactNowPlayingView.swift
//  DevNotch
//
//  Created on 2026-01-06.
//

import SwiftUI

struct CompactNowPlayingView: View {
    @ObservedObject private var controller = MediaRemoteController.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // Artwork
            if let data = controller.nowPlayingInfo?.artworkData, let nsImage = NSImage(data: data) {
                 Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 18, height: 18) // Smaller as requested
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if controller.nowPlayingInfo != nil {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    )
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.white.opacity(0.5))
            }

            if let info = controller.nowPlayingInfo {
                // Combined Artist - Track
                Text("\(info.artistName) - \(info.trackName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("Not playing")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Animated Sound Bar
            if controller.nowPlayingInfo?.isPlaying == true {
                WaveformView(color: Color.orange)
                    .frame(width: 20, height: 12)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity)
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
            .background(Color.black.opacity(0.85))
    }
}
