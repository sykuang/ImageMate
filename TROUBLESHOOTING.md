# Testing "Open With" for ImageMate

## ✅ Fix Applied!

The Info.plist has been updated and ImageMate is now registered with the system.

## How to Test

### Test 1: Open an Image
1. Find any image file on your Mac (.jpg, .png, etc.)
2. **Right-click** on it
3. Select **"Open With"**
4. You should see **"ImageMate"** in the list!
5. Click ImageMate to open the image

### Test 2: Open a Folder
1. Find any folder with images
2. **Right-click** on the folder
3. Hold the **Option (⌥) key** to see "Open With" for folders
4. Select **"ImageMate"**
5. The library view should appear!

### Test 3: Set as Default (Optional)
1. Right-click an image
2. Select **"Get Info"** (⌘I)
3. In "Open with:" section, choose **ImageMate**
4. Click **"Change All..."** to make it default for this file type

## If ImageMate Still Doesn't Appear

Try these steps in order:

### Step 1: Re-register
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/ImageMate.app
```

### Step 2: Rebuild LaunchServices Database
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -r -domain local -domain system -domain user
```

### Step 3: Restart Everything
```bash
killall Finder
killall Dock
```

### Step 4: Log Out and Back In
If nothing else works, log out of macOS and log back in.

## What Was Fixed

The problem was that Xcode 16 auto-generates the Info.plist and doesn't include our custom  CFBundleDocumentTypes from the source Info.plist file.

**Solution Applied:**
- Added CFBundleDocumentTypes directly to `/Applications/ImageMate.app/Contents/Info.plist`
- Registered all major image formats (JPEG, PNG, GIF, BMP, TIFF, HEIC, HEIF)
- Added folder support
- Re-registered with LaunchServices
- Restarted Finder and Dock

## Permanent Fix for Future Builds

To ensure future builds include document types, we need to add them as build settings. Here's how:

1. Open Xcode
2. Select the ImageMate target
3. Go to Build Settings
4. Add these custom settings (click + to add User-Defined Setting):
   - `INFOPLIST_KEY_CFBundleDocumentTypes` 

Or use a custom Info.plist by:
1. Set `GENERATE_INFOPLIST_FILE` = `NO`
2. Set `INFOPLIST_FILE` = `Info.plist`

For now, the installed app at `/Applications/ImageMate.app` is fully configured and should work!

## Verification

Run this to confirm document types are registered:
```bash
plutil -p /Applications/ImageMate.app/Contents/Info.plist | grep -A 5 CFBundleDocumentTypes
```

You should see image and folder document types listed.

🎉 Now try right-clicking an image - ImageMate should be there!
