# DevNotch — macOS Notch App

A native macOS app that transforms your MacBook's notch into a useful
information hub.

## Features

- **Now Playing Music**: Displays currently playing music with hover-to-expand
  controls
- **GitHub Copilot Usage**: Shows your Copilot usage statistics and limits
- **Native Integration**: Built with SwiftUI + React for optimal performance

## Architecture

- **Host**: Native SwiftUI macOS app
- **UI**: Native SwiftUI views (NowPlaying, Copilot usage)
- **Bridge**: Minimal Swift-only implementation (Keychain, MediaRemote)

## Development

### Prerequisites

- macOS 14 Sonoma or later
- Xcode 16 or later
- Node.js 18+

### Setup

1. Install dependencies:
```bash
npm install
```

2. Start Vite dev server:
```bash
npm run dev
```

3. Open and run the Xcode project:
```bash
npm run open:xcode
```

Then press `Cmd + R` in Xcode to build and run.

## Production Build

```bash
npm run build:mac
```

## Project Structure

```
/
├── macos/              # Native SwiftUI app
├── src/                # React frontend
├── dist/               # Built web assets
└── plan.md             # Detailed implementation plan
```

For detailed build instructions, see [macos/README.md](macos/README.md).

## References

- [NotchDrop](https://github.com/Lakr233/NotchDrop) - Notch window management
- [boring.notch](https://github.com/TheBoredTeam/boring.notch) - MediaRemote
  integration
