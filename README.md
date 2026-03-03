# ImageMate

A lightweight, native macOS image viewer built with SwiftUI. Fast browsing, keyboard navigation, zoom & pan, image export, and auto-resizing windows — all in a sandboxed app.

[![PR Quality Gate](https://github.com/sykuang/ImageMate/actions/workflows/pr.yml/badge.svg)](https://github.com/sykuang/ImageMate/actions/workflows/pr.yml)
[![Release](https://github.com/sykuang/ImageMate/actions/workflows/release.yml/badge.svg)](https://github.com/sykuang/ImageMate/actions/workflows/release.yml)

## Features

- **Browse images** — Open files or entire folders; drag & drop supported
- **Thumbnail strip** — Always-visible or auto-hide mode (configurable)
- **Zoom & pan** — Pinch-to-zoom on trackpad, drag to pan, +/- controls
- **Auto-resize window** — Window adapts to image size (like macOS Preview)
- **Image export** — Convert to HEIC, JPEG, PNG, or TIFF (`⌘⇧S`)
- **Image info panel** — Filename, dimensions, file size, path
- **Keyboard shortcuts** — `←` `→` navigate, `⌘O` open, `⌘,` settings, `ESC` dismiss

### Supported Formats

JPEG · PNG · GIF · BMP · TIFF · HEIC/HEIF · WebP · SVG

## Requirements

- macOS 14.0 (Sonoma) or later

## Installation

### Download

1. Download the latest `ImageMate.dmg` from [Releases](https://github.com/sykuang/ImageMate/releases)
2. Open the DMG and drag ImageMate to **Applications**
3. On first launch, macOS Gatekeeper may block the unsigned app. To allow it:
   - **Right-click** ImageMate.app → **Open** → click **Open** in the dialog, or
   - Run in Terminal: `xattr -cr /Applications/ImageMate.app`

### Build from Source

```bash
git clone https://github.com/sykuang/ImageMate.git
cd ImageMate
xcodebuild build \
  -workspace ImageMate.xcworkspace \
  -scheme ImageMate \
  -configuration Release
```

> Requires Xcode 16.3+ (Swift 6.1).

## Development

### Project Structure

```
ImageMate/
├── ImageMate.xcworkspace/          # Open this in Xcode
├── ImageMate/                      # App shell (entry point, assets, entitlements)
├── ImageMatePackage/               # SPM package — primary development area
│   ├── Sources/ImageMateFeature/   #   Feature code (views, view models, exporters)
│   └── Tests/ImageMateFeatureTests/#   Unit tests (Swift Testing)
├── ImageMateUITests/               # UI tests (XCTest)
├── Config/                         # XCConfig build settings
├── .github/workflows/              # CI/CD pipelines
└── .swiftlint.yml                  # Lint configuration
```

Business logic lives in the **ImageMatePackage** SPM package. The app target is a thin shell that imports `ImageMateFeature`.

### Running Tests

```bash
# Unit tests (37 tests, Swift Testing framework)
cd ImageMatePackage && swift test

# Full build + all tests via Xcode
xcodebuild test \
  -workspace ImageMate.xcworkspace \
  -scheme ImageMate \
  -destination 'platform=macOS'
```

### Linting

```bash
brew install swiftlint
swiftlint lint
```

## CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **PR Quality Gate** | Pull request → `main` | SwiftLint ‖ Build + unit tests + UI tests |
| **Release** | Push tag `v*` | Archive → sign → DMG → notarize → GitHub Release |

### Release Process

1. Tag a version: `git tag v1.2.0 && git push --tags`
2. The release workflow builds an ad-hoc signed DMG and publishes a GitHub Release automatically.

> **Note:** The app is not notarized (no paid Apple Developer account). Users will need to bypass Gatekeeper on first launch (see [Installation](#installation)).

## License

© 2026 sykuang. All rights reserved.