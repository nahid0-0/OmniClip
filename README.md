# OmniClip

A lightweight clipboard manager for macOS that runs in the menu bar.

## Features

- 📋 Automatic clipboard history tracking
- 🖼️ Screenshot detection and management
- ⚡ Quick access via menu bar
- 🔍 Preview clipboard items before pasting
- ⌨️ Global hotkey support (⌘ + Shift + V)
- 🗑️ Easy item management (delete, clear all)
- 💾 Persistent storage across app restarts
- 🎨 Clean, native macOS interface

## Download

**[Download OmniClip.app](https://github.com/nahid0-0/OmniClip/raw/main/build/OmniClip.app.zip)**

Or download directly from the repository:
- [OmniClip.app folder](https://github.com/nahid0-0/OmniClip/tree/main/build/OmniClip.app)

## Installation

1. Download the app using the link above
2. Unzip if downloaded as .zip
3. Move `OmniClip.app` to your `/Applications` folder
4. Right-click the app and select "Open" (first time only to bypass Gatekeeper)
5. The app will appear in your menu bar

## Usage

- Click the clipboard icon in the menu bar to view history
- Press `⌘ + Shift + V` to quickly access clipboard history
- Click any item to copy it to clipboard
- Hover over items to see a larger preview
- Use Settings to configure behavior

## Building from Source

### Requirements
- macOS 13.0 or later
- Xcode Command Line Tools
- Swift compiler

### Build Steps

```bash
# Clone the repository
git clone https://github.com/nahid0-0/OmniClip.git
cd OmniClip

# Run the build script
./build.sh

# The app will be created at build/OmniClip.app
open build/OmniClip.app
```

Or open `OmniClip.xcodeproj` in Xcode and build normally.

## System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel processor

## Permissions

OmniClip requires the following permissions:
- **Accessibility**: To capture global hotkeys
- **Screen Recording**: To detect and manage screenshots (optional)

## License

Copyright © 2026 Nahid Rahman. All rights reserved.

## Contributing

Issues and pull requests are welcome!
