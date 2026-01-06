# DevNotch — macOS SwiftUI Notch App (Hybrid)

## Goal
Create a **native macOS SwiftUI app** that lives in the screen notch,
displaying:
1.  **Now Playing Music**: With hover-to-expand controls and details.
2.  **GitHub Copilot Usage**: Visual stats (ported from existing project).

## Architecture: Native SwiftUI (no WebView)
We will switch to a **pure native SwiftUI** approach. The notch UI will be
implemented entirely in SwiftUI, removing `WKWebView` and React as runtime
dependencies for the notch UI. Native views will provide better performance and
simpler integration with macOS APIs.

* **Host & UI**: SwiftUI macOS app (`DevNotch.app`) — all UI implemented in
  SwiftUI views (NowPlaying, Copilot usage, controls)
* **Interop**: Keep `KeychainHelper` and `MediaRemoteController` in Swift (no JS
  bridge required for core notch features)

## References & Inspiration
*   **[NotchDrop](https://github.com/Lakr233/NotchDrop)**:
    * *Adopting*: Window management (floating `NSPanel`), Drag & Drop handling,
      Notch geometry calculations.
*   **[boring.notch](https://github.com/TheBoredTeam/boring.notch)**:
    * *Adopting*: `MediaRemote` framework integration for robust "Now Playing"
      detection without direct AppleScript.



## Technical Specification

### 1. macOS Host (SwiftUI)
The core container that replaces Tauri.

*   **Window Management**:
    * Use `NSPanel` instead of `NSWindow` for auxiliary/floating behavior.
    * Attributes: `.nonactivatingPanel`, `.borderless`, `.transparent`.
    * Level: `.mainMenu + 1` (to sit above the menu bar).
    * Collection Behavior: `.canJoinAllSpaces`, `.fullScreenAuxiliary`.
*   **Notch Handling**:
    * Detect screen notch metrics (`safeAreaInsets`).
    * Position window exactly under/inside the notch area.
    * **Hover State**: Track `CGEvent` or `NSTrackingArea` to detect mouse
      enter/exit on the notch.
    * **Animation**: Swift smoothly animates the window frame height; React
      animates the DOM content.

### 2. Native Features (Swift)
*   **Music Integration**:
    * Implement an observer for `MediaRemote` framework (private framework, but
      widely used in referenced repos).
    * Listen for: Track change, Play/Pause state, Artwork.
    * Broadcast updates to Web via Bridge.
*   **Secure Storage**:
    * Store GitHub Access Token in macOS **Keychain**.
*   **System Integration**:
    * "Launch at Login" capability.
    * Global hotkey (optional) to peek.

### 3. Frontend (React/Web)
*   **View Modes**:
    * `Compact`: Height ~32px. Shows Copilot Sparkline / Mini Music Note.
    * `Expanded`: Height ~180px. Shows Album Art, Tracks, Controls, Copilot
      Charts.
*   **Bridge Layer**:
    * `window.native.on('mediaInfo', (data) => ...)`
    * `window.native.on('hover', (state) => ...)`
    * `window.native.send('control', { action: 'next' })`



## Implementation Plan

### Phase 1: Native Scaffold (The "Container")
1.  Create `macos/DevNotch` Xcode project (SwiftUI).
2.  Implement `NotchWindowController`:
    * Configure `NSPanel` properties (transparent, floating).
    * Hardcode position to top-center (simulating notch).
3.  Implement `WebView` wrapper:
    * Load `http://localhost:5173` (Dev) or `Bundle.main.url(forResource: ...)`
      (Prod).
    * Make WebView transparent.

### Phase 2: React UI Adaptation
1.  Update React app to handle transparent background.
2.  Create `NotchContainer` component:
    * Listens for "Hover" signals (or simulates them for now).
    * Switches CSS classes for animations.
3.  Mock "Now Playing" UI in React to verify layout.

### Phase 3: The Bridge & Interactions
1.  **Swift -> JS**: Inject JavaScript to dispatch CustomEvents (`notch-hover`,
    `media-update`).
2.  **JS -> Swift**: `window.webkit.messageHandlers.devnotch.postMessage(...)`
    for controls.
3.  **Hover Logic**:
    * Swift: Detect mouse over Notch area -> Expand Window Frame -> Send signal.
    * React: Receive signal -> Fade in controls.

### Phase 4: Native Integrations (The "Hard Stuff")
1.  **MediaRemote (Swift)**:
    * Port `MRMediaRemoteGetNowPlayingInfo` logic from `boring.notch`.
    * Convert artwork data (NSData) to Base64 -> Send to UI.
2.  **GitHub Auth**:
    * Port Logic: Keep Auth flow in React, but save token via Bridge to
      Keychain.
    * API: React calls GitHub API directly (using token).

### Phase 5: Polish & Build
1.  Build React (`npm run build`).
2.  Copy `dist/` to Xcode `Destination` phase.
3.  Archive & Notarize.



## Directory Structure Changes
```text
/
├── macos/                  <-- NEW: Xcode Project
│   ├── DevNotch/
│   │   ├── App.swift
│   │   ├── NotchWindow.swift
│   │   ├── MediaRemote/    <-- Native Music Logic
│   │   └── Bridge/         <-- WebKit Handlers
│   └── DevNotch.xcodeproj
├── src/                    <-- Existing React App
│   ├── components/
│   │   └── ...
│   └── hooks/
│       └── useNativeBridge.ts
└── package.json            <-- Add "build:mac" scripts
```
