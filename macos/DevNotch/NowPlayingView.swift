//
//  NowPlayingView.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject private var controller = MediaRemoteController.shared
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Artwork
            if let data = controller.nowPlayingInfo?.artworkData, let nsImage = NSImage(data: data) {
                 Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .onTapGesture {
                        controller.openMusicApp()
                    }
            } else if controller.nowPlayingInfo != nil {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let info = controller.nowPlayingInfo {
                    Text(info.trackName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(info.artistName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    Text(info.albumName ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Controls
            if controller.nowPlayingInfo != nil {
                HStack(spacing: 8) {
                    Button(action: { controller.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        if controller.nowPlayingInfo?.isPlaying == true {
                            controller.pause()
                        } else {
                            controller.play()
                        }
                    }) {
                        Image(systemName: controller.nowPlayingInfo?.isPlaying == true ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                    }
                    Button(action: { controller.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
            .frame(width: 360, height: 64)
            .background(Color.black.opacity(0.85))
    }
}
