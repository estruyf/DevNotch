//
//  MediaRemoteController.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import Foundation
import AppKit
import SwiftUI
import os

// MediaRemote framework imports (private framework)
@objc protocol MediaRemoteProtocol {
    func MRMediaRemoteGetNowPlayingInfo(_ queue: DispatchQueue, _ completion: @escaping ([String: Any]) -> Void)
    func MRMediaRemoteRegisterForNowPlayingNotifications(_ queue: DispatchQueue)
    func MRMediaRemoteSendCommand(_ command: Int, _ options: [String: Any]?)
}

class MediaRemoteController: ObservableObject {
    static let shared = MediaRemoteController()
    
    @Published var nowPlayingInfo: NowPlayingInfo?
    
    private var observerAdded = false
    
    // MediaRemote command constants
    private enum Command: Int {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case stop = 3
        case nextTrack = 4
        case previousTrack = 5
    }
    
    private var lastTrackID: String = ""
    private var timer: Timer?
    
    init() {
        setupNotificationObserver()
        
        // Safely fetch now playing info
        do {
            fetchNowPlayingInfo()
        } catch {
            os_log("Error fetching initial now playing info: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
        }
        
        // Poll every 2 seconds to ensure sync
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.fetchNowPlayingInfo()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func setupNotificationObserver() {
        // Observers for validation (DistributedNotificationCenter is required for these public-but-undocumented notifications)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(nowPlayingInfoChanged),
            name: NSNotification.Name("com.apple.iTunes.playerInfo"),
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(nowPlayingInfoChanged),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }
    
    @objc private func nowPlayingInfoChanged() {
        fetchNowPlayingInfo()
    }
    
    func fetchNowPlayingInfo() {
        // Universal AppleScript to check Spotify then Music
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    return "Spotify|||" & name of current track & "|||" & artist of current track & "|||" & album of current track & "|||playing"
                else if player state is paused then
                    return "Spotify|||" & name of current track & "|||" & artist of current track & "|||" & album of current track & "|||paused"
                end if
            end tell
        end if
        
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                     return "Music|||" & name of current track & "|||" & artist of current track & "|||" & album of current track & "|||playing"
                else if player state is paused then
                     return "Music|||" & name of current track & "|||" & artist of current track & "|||" & album of current track & "|||paused"
                end if
            end tell
        end if
        
        return "not_playing"
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                var error: NSDictionary?
                guard let scriptObject = NSAppleScript(source: script) else {
                    os_log("Failed to create AppleScript object", log: OSLog.default, type: .debug)
                    return
                }
                
                let output = scriptObject.executeAndReturnError(&error)
                
                DispatchQueue.main.async {
                    // Log any errors for debugging
                    if let error = error {
                        os_log("AppleScript error in fetchNowPlayingInfo: %{public}@", log: OSLog.default, type: .error, String(describing: error))
                    }
                    
                    guard error == nil, let result = output.stringValue, result != "not_playing" else {
                        if self.nowPlayingInfo != nil {
                            withAnimation {
                                self.nowPlayingInfo = nil
                            }
                        }
                        self.lastTrackID = ""
                        return
                    }
                    
                    let components = result.components(separatedBy: "|||")
                    guard components.count >= 5 else { return }
                    
                    let trackID = "\(components[1])-\(components[2])"
                    var currentArtwork = self.nowPlayingInfo?.artworkData
                    let isPlaying = (components[4] == "playing")
                    
                    // Check if track changed to fetch new artwork
                    if trackID != self.lastTrackID {
                        self.lastTrackID = trackID
                        currentArtwork = nil // Reset while fetching
                        self.fetchArtwork(appName: components[0])
                    }
                    
                    // Create info with existing artwork (will be updated by fetchArtwork completion)
                    // We don't overwrite if we are just polling playback state
                    if self.nowPlayingInfo?.trackName == components[1] {
                        currentArtwork = self.nowPlayingInfo?.artworkData
                    }
                    
                    let info = NowPlayingInfo(
                        trackName: components[1],
                        artistName: components[2],
                        albumName: components[3],
                        isPlaying: isPlaying,
                        appName: components[0],
                        artworkData: currentArtwork
                    )
                    
                    // Prevent unnecessary UI updates/flickers
                    if self.nowPlayingInfo != info {
                        withAnimation {
                            self.nowPlayingInfo = info
                        }
                    }
                }
            } catch {
                os_log("Exception in fetchNowPlayingInfo: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
    }
    
    func openMusicApp() {
        guard let appName = nowPlayingInfo?.appName else { return }
        
        // Map common names to Bundle IDs or just open by name
        let bundleID: String
        switch appName {
        case "Spotify": bundleID = "com.spotify.client"
        case "Music": bundleID = "com.apple.Music"
        default: return
        }
        
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func fetchArtwork(appName: String) {
        let script: String
        if appName == "Spotify" {
            script = "tell application \"Spotify\" to return artwork url of current track"
        } else {
             script = "tell application \"Music\" to return raw data of artwork 1 of current track"
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                let descriptor = scriptObject.executeAndReturnError(&error)
                
                var data: Data?
                
                if appName == "Spotify" {
                    // Spotify returns URL string
                    if let urlString = descriptor.stringValue, let url = URL(string: urlString) {
                        data = try? Data(contentsOf: url)
                    }
                } else {
                    // Music returns raw data
                    data = descriptor.data
                }
                
                if let validData = data {
                    DispatchQueue.main.async {
                        guard var info = self?.nowPlayingInfo else { return }
                        info.artworkData = validData
                        withAnimation {
                            self?.nowPlayingInfo = info
                        }
                    }
                }
            }
        }
    }
    
    func play() {
        if nowPlayingInfo?.appName == "Spotify" {
            executeAppleScript("tell application \"Spotify\" to play")
        } else {
            executeAppleScript("tell application \"Music\" to play")
        }
    }
    
    func pause() {
        if nowPlayingInfo?.appName == "Spotify" {
            executeAppleScript("tell application \"Spotify\" to pause")
        } else {
            executeAppleScript("tell application \"Music\" to pause")
        }
    }
    
    func nextTrack() {
        if nowPlayingInfo?.appName == "Spotify" {
            executeAppleScript("tell application \"Spotify\" to next track")
        } else {
            executeAppleScript("tell application \"Music\" to next track")
        }
    }
    
    func previousTrack() {
        if nowPlayingInfo?.appName == "Spotify" {
            executeAppleScript("tell application \"Spotify\" to previous track")
        } else {
            executeAppleScript("tell application \"Music\" to previous track")
        }
    }
    
    private func executeAppleScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
                if let error = error {
                    print("AppleScript error: \(error)")
                }
            }
        }
    }
}

struct NowPlayingInfo: Codable, Equatable {
    let trackName: String
    let artistName: String
    let albumName: String?
    let isPlaying: Bool
    let appName: String?
    var artworkData: Data?
    
    static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        return lhs.trackName == rhs.trackName &&
               lhs.artistName == rhs.artistName &&
               lhs.albumName == rhs.albumName &&
               lhs.isPlaying == rhs.isPlaying &&
               lhs.appName == rhs.appName &&
               lhs.artworkData == rhs.artworkData
    }
}
