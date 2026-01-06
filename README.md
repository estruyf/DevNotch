# DevNotch — macOS Notch App

A native macOS app that transforms your MacBook's notch into a useful
information hub.

## Features

- **Now Playing Music**: Displays currently playing music with simple controls.
- **GitHub Copilot Usage**: Shows your Copilot usage statistics directly in the
  notch.
- **Privacy Focused**: No data collection, everything runs locally.
- **Native Performance**: Built entirely with Swift and SwiftUI for macOS.

## Usage

### Getting Started
1. Launch **DevNotch**. The app will reside in your screen's notch area (top
   center).
2. **Right-click** on the notch to access the Context Menu.
3. Select **Settings...** to configure the app.

### GitHub Copilot Integration
To see your usage stats:
1. Open **Settings** (Right-click notch -> Settings...).
2. Click **Sign In with GitHub** to authenticate via the secure Device Flow.
3. Alternatively, if you have a token (starts with `ghu_`), use the "Manual
   Token Entry" section at the bottom of the Settings > Copilot page.

### Controls
- **Hover/Click**: Expand the notch to see detailed media info and Copilot
  stats.
- **Right-Click**: Open context menu (Settings, Quit).

## Installation

Download the latest `.dmg` release, open it, and drag **DevNotch** to your
**Applications** folder.

## Development

### Prerequisites

- macOS 14 Sonoma or later
- Xcode 16 or later
- Node.js 18+ (for build scripts)

### Setup

1. Install dependencies (for scripts):
```bash
npm install
```

2. Open the project in Xcode:
```bash
npm run open:xcode
```

3. Build and Run using Xcode (`Cmd + R`).

### Build

To create a production DMG:

```bash
npm run build:dmg
```

This command compiles the Swift project and packages it into a draggable
installer.

## Architecture

- **Language**: Swift 5.10+
- **UI Framework**: SwiftUI
- **Window Management**: `NSPanel` subclass for floating notch window.
- **Auth**: Native implementation of GitHub Device Flow.

## Project Structure

```
/
├── macos/              # Native SwiftUI app project
│   ├── DevNotch/       # Source code
│   └── DevNotch.xcodeproj
├── scripts/            # Build and utility scripts
└── package.json        # Build command orchestration
```

## References

- [NotchDrop](https://github.com/Lakr233/NotchDrop) - Inspiration for notch
  window management.
