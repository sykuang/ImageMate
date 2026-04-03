# ImageMate Installation Guide

## Quick Install

ImageMate has been built and installed to `/Applications/ImageMate.app`!

## Making ImageMate appear in "Open With" menu

To make ImageMate appear in Finder's right-click "Open With" menu, follow these steps:

### Option 1: Automatic (Recommended)

Run this command in Terminal:

```bash
# Register the app with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

Then restart Finder:

```bash
killall Finder
```

### Option 2: Manual Setup

1. **Right-click on any image file** (JPG, PNG, etc.)
2. Select **"Get Info"** (or press ⌘I)
3. In the **"Open with:"** section, click the dropdown
4. Select **"Other..."**
5. Navigate to `/Applications` and select **ImageMate.app**
6. Click **"Change All..."** to make ImageMate the default for this file type (optional)

### Option 3: For Folders

To open folders with ImageMate:

1. **Right-click on a folder**
2. Select **"Get Info"**
3. You may need to hold **Option** key to see "Open With" options for folders
4. Or simply drag and drop a folder onto the ImageMate app icon

## Features

Once installed, you can:

- ✅ **Right-click any image** → "Open With" → "ImageMate"
- ✅ **Right-click a folder** → "Open With" → "ImageMate" (shows library view)
- ✅ **Drag & drop images** onto the ImageMate app icon
- ✅ **Drag & drop folders** onto the ImageMate app icon
- ✅ **Double-click images** if you set ImageMate as default

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- BMP (.bmp)
- TIFF (.tiff, .tif)
- HEIC/HEIF (.heic, .heif)
- WebP (.webp)
- SVG (.svg)

## Uninstallation

To remove ImageMate:

```bash
rm -rf /Applications/ImageMate.app
```

Then reset LaunchServices:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

## Troubleshooting

### ImageMate doesn't appear in "Open With" menu

1. Make sure the app is in `/Applications`
2. Run the lsregister command above
3. Restart Finder: `killall Finder`
4. Log out and log back in (if still not working)

### Permission denied errors

Make sure ImageMate has permission to access files:

1. Open **System Settings** → **Privacy & Security** → **Files and Folders**
2. Find **ImageMate** and grant access as needed

## Building from Source

If you want to rebuild and reinstall:

```bash
cd /Users/kenkuang/src/ImageMate

# Clean build
xcodebuild clean -workspace ImageMate.xcworkspace -scheme ImageMate

# Build release version
xcodebuild build -workspace ImageMate.xcworkspace -scheme ImageMate -configuration Release

# Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/ImageMate-*/Build/Products/Release/ImageMate.app /Applications/

# Register with system
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/ImageMate.app

# Restart Finder
killall Finder
```

Enjoy using ImageMate! 🖼️
