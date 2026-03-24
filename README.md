# What Did They Say

A local, privacy-first translation overlay for macOS. Translate any text on screen — no cloud required.

## Features

- **Menu bar app** — lives quietly in your menu bar, zero Dock clutter
- **Text translation** — paste or type any text, get instant translations
- **Screen translation** — one shortcut to capture your screen, detect all text via Vision OCR, and overlay translations in place
- **Apple Translation** (primary) — on-device, fast, supports 20+ languages (macOS 14+)
- **NLLB-200 fallback** — Meta's 200-language offline model via Core ML (optional download, ~600 MB)
- **Global shortcuts** — `⌘⇧T` for text popover, `⌘⇧S` for screen translation
- **Launch at Login** — optional, toggle from right-click menu
- **15 languages** — EN, ES, FR, DE, PT, IT, NL, RU, ZH, JA, KO, AR, HI, TR, PL

## Requirements

| Component | Minimum |
|-----------|---------|
| macOS | 14.0 Sonoma |
| Xcode | 15.0 |
| Swift | 5.9 |

Apple Translation (on-device) requires macOS 15 Sequoia for the programmatic API. On macOS 14, translation falls back to the NLLB engine or prompts the user to upgrade.

## Build & Run

### With Xcode (recommended)

```bash
git clone https://github.com/your-org/what-did-they-say
cd what-did-they-say/Lingo
open Package.swift           # Opens in Xcode
```

In Xcode:
1. Select the **WhatDidTheySay** scheme
2. Set your Development Team in **Signing & Capabilities**
3. Press **⌘R** to build and run

### With Swift CLI

```bash
cd what-did-they-say/Lingo
swift build -c release
.build/release/WhatDidTheySay
```

> Note: Running from the terminal may require granting Screen Recording permission manually in
> **System Settings → Privacy & Security → Screen Recording → What Did They Say**.

## Permissions

What Did They Say requires two permissions (prompted automatically on first launch):

| Permission | Why |
|------------|-----|
| **Screen Recording** | ScreenCaptureKit screenshot for screen translation |
| **Network** | Apple Translation model downloads (first use per language pair) |

## Usage

| Action | How |
|--------|-----|
| Open text translator | Click menu bar icon **or** `⌘⇧T` |
| Translate screen | Right-click menu bar icon → *Translate Screen* **or** `⌘⇧S` |
| Stop screen overlay | Press `⌘⇧S` again, or overlays auto-dismiss after 8 s |
| Copy translation | Click the copy button in the popover result area |
| Change language | Use the language pickers in the popover header |
| Launch at Login | Right-click menu bar icon → *Launch at Login* |

## Project Structure

```
Lingo/
├── Package.swift
├── Lingo.entitlements
├── Resources/Assets.xcassets/      ← App icon + menu bar icon assets
└── Sources/
    ├── LingoCore/                   ← Testable business logic (no AppKit)
    │   ├── Engine/
    │   │   ├── TranslationEngine.swift   ← Protocol + CompositeEngine
    │   │   ├── AppleTranslationEngine.swift
    │   │   ├── NLLBEngine.swift          ← Stub; enable via Package.swift
    │   │   └── ModelCache.swift
    │   └── Utils/
    │       └── Preferences.swift         ← UserDefaults + LaunchAtLogin
    └── Lingo/                       ← App executable (AppKit/SwiftUI)
        ├── LingoApp.swift           ← @main entry point
        ├── AppDelegate.swift        ← App lifecycle, shortcut registration
        ├── ScreenTranslation/
        │   ├── ScreenTranslator.swift         ← Orchestrator
        │   ├── ScreenCaptureManager.swift
        │   ├── TextRegionDetector.swift        ← Vision OCR
        │   ├── TextOverlayRenderer.swift
        │   └── HoverTranslationController.swift
        └── UI/
            ├── MenuBarController.swift
            ├── PopoverView.swift
            ├── LanguageButton.swift
            ├── TranslationResultOverlay.swift
            └── ScreenTranslationOverlay.swift
```

## Enabling NLLB-200 Offline Fallback

1. Uncomment the `swift-transformers` dependency in `Package.swift`
2. Uncomment the import and implementation in `NLLBEngine.swift`
3. On first use, the app will prompt to download the model (~600 MB to Application Support)

## Adding App Icons

The `Resources/Assets.xcassets/AppIcon.appiconset/` directory is ready for PNG assets.
Required sizes: 16, 32, 128, 256, 512 pt (1× and 2× each).

The menu bar icon uses an SF Symbol (`globe`) by default. Replace it in `MenuBarController.swift` with your custom template image from `MenuBarIcon.imageset`.

## Privacy

What Did They Say processes everything locally:
- Screen captures never leave your device
- Apple Translation runs on-device (no data sent to Apple servers)
- NLLB-200 runs entirely offline once downloaded

## License

MIT
