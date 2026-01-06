# DevNotch - macOS Build Instructions

## Prerequisites

- macOS 14 Sonoma or later
- Xcode 16 or later
- Node.js 18+

## Development

### 1. Start the Vite dev server
```bash
npm install
npm run dev
```

### 2. Open Xcode project
```bash
npm run open:xcode
```

or manually:
```bash
open macos/DevNotch.xcodeproj
```

### 3. Build and run in Xcode
- Select your Mac as the target
- Press `Cmd + R` to build and run

The app will load the React frontend from `http://localhost:5173` in development
mode.

## Production Build

### Build the macOS app (Swift-only UI)

1. Build the app using Swift Package Manager:
```bash
cd macos
swift build -c release
```

2. The app executable will be in `.build/release/DevNotch` (or use Xcode Archive
   for packaging and notarization).

### Copilot device-flow configuration

Set the `CopilotClientID` key in `macos/DevNotch/Info.plist` to your OAuth app
client id to enable GitHub device-flow sign-in for Copilot usage. If this key is
empty, the sign-in will not start and an error will be shown in the app.

## Project Structure

```
/
├── macos/                      # SwiftUI macOS app
│   ├── DevNotch/
│   │   ├── DevNotchApp.swift   # App entry point
│   │   ├── NotchWindow.swift   # Custom NSPanel
│   │   ├── Bridge/             # JS-Swift bridge
│   │   └── MediaRemote/        # Music integration
│   └── DevNotch.xcodeproj
├── src/                        # React frontend
│   ├── hooks/
│   │   └── useNativeBridge.ts  # Native API wrapper
│   └── ...
└── dist/                       # Built web assets (copied to app)
```

## Features

- **Now Playing**: Displays currently playing music from Apple Music/Spotify
- **Hover Expansion**: Window expands when hovering over notch area
- **GitHub Copilot**: Shows usage statistics (requires auth)
- **Secure Storage**: Tokens stored in macOS Keychain

## Debugging

- Open Safari Developer menu to inspect WebView
- Enable "Develop" menu in Safari Preferences
- Select "DevNotch" from the Develop menu
