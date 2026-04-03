# Debugging "Open With" Issue

## ✅ Logging Added

The app now has comprehensive logging at every step of the "Open With" flow:

### Log Locations

**App Initialization:**
- 🚀 App initializing
- ✅ Application did finish launching
- 📋 Bundle ID and registered document types

**File Opening Flow:**
1. **AppDelegate Methods:**
   - 🎯 `application:open:` - macOS sends files here
   - 🎯 `openFile:` - Alternative file opening method
   - 🎯 `openFiles:` - Multiple files opening method
   - 📄 Lists all URLs/files being opened

2. **Notification Flow:**
   - 📨 Posting OpenURLFromFinder notification
   - 🎯 ContentView receives notification
   - 📥 Processing URL

3. **File Processing:**
   - 🔐 Security-scoped resource access status
   - 📁 File exists check and directory check
   - 📂 Folder processing (if folder)
   - 🖼️ Image file processing (if image)
   - ✅ Success or ❌ Error messages

## 🔍 How to Debug

### Step 1: View Logs in Real-Time

In one terminal, run:
```bash
./view-logs.sh
```

### Step 2: Install the App

```bash
# Mount the DMG
open ImageMate.dmg

# Copy to Applications (in Finder or via terminal)
cp -R /Volumes/ImageMate/ImageMate.app /Applications/

# Force re-register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f /Applications/ImageMate.app

# Restart Finder
killall Finder
```

### Step 3: Test "Open With"

1. Find any image file (PNG, JPEG, etc.)
2. Right-click on it
3. Select "Open With" → "ImageMate"

**Watch the terminal** - you should see logs like:
```
🚀 ImageMate app initializing
✅ AppDelegate: Application did finish launching
📋 Bundle ID: com.primattek.ImageMate
🎯 AppDelegate: application:open: called with 1 URLs
   📄 URL: /path/to/your/image.jpg
📨 Posting OpenURLFromFinder notification
🎯 ContentView: Received OpenURLFromFinder notification
📥 ContentView: Processing URL: /path/to/your/image.jpg
🖼️ Processing as single image file
✅ Image loaded successfully
```

## 🔍 What to Look For

### If NO logs appear when using "Open With":
- ❌ macOS is NOT calling the app
- **Problem:** LaunchServices doesn't recognize the app
- **Solution:** Check Info.plist registration

### If logs show up to "Application did finish launching" but nothing else:
- ❌ App launches but receives no file
- **Problem:** File association not working
- **Solution:** Re-register with LaunchServices

### If logs show "application:open:" but notification not received:
- ❌ AppDelegate works but ContentView doesn't receive notification
- **Problem:** NotificationCenter issue
- **Solution:** Check app lifecycle

### If logs show "File does not exist":
- ❌ File path is wrong or permissions denied
- **Problem:** Sandbox or security-scoped resources
- **Solution:** Check entitlements

## 🛠️ Quick Fixes

### Fix 1: Re-register LaunchServices
```bash
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user
```

### Fix 2: Check if app is registered
```bash
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump | grep -i imagemate
```

### Fix 3: Check app signature
```bash
codesign -dv /Applications/ImageMate.app
```

### Fix 4: Verify Info.plist
```bash
defaults read /Applications/ImageMate.app/Contents/Info.plist CFBundleDocumentTypes
```

## 📊 Expected Output

When "Open With" works correctly, you should see:

```
🚀 ImageMate app initializing
✅ AppDelegate: Application did finish launching  
📋 Bundle ID: com.primattek.ImageMate
📋 Registered document types: (
    {
        CFBundleTypeName = Image;
        CFBundleTypeRole = Viewer;
        LSHandlerRank = Default;
        LSItemContentTypes = (
            "public.image"
        );
    }
)
🎯 AppDelegate: application:open: called with 1 URLs
   📄 URL: /Users/you/Pictures/photo.jpg
📨 Posting OpenURLFromFinder notification for: /Users/you/Pictures/photo.jpg
🎯 ContentView: Received OpenURLFromFinder notification
📥 ContentView: Processing URL: /Users/you/Pictures/photo.jpg
🎯 handleFinderOpen called with URL: /Users/you/Pictures/photo.jpg
🔐 Security-scoped resource access: true
📁 File exists: true, Is directory: false
🖼️ Processing as single image file
📂 Parent directory: /Users/you/Pictures
✅ Image loaded successfully
```

## 🚨 Common Issues

1. **"Open With" doesn't show ImageMate**
   - Re-register: `lsregister -f /Applications/ImageMate.app`
   - Restart Finder: `killall Finder`

2. **App shows but nothing happens when clicked**
   - Check logs - AppDelegate should receive `application:open:`
   - If not receiving, Info.plist may be wrong

3. **App receives file but can't open it**
   - Check security-scoped resource logs
   - Verify entitlements include file access

## 📝 Report Template

When reporting issues, include:

1. **Full log output** from `./view-logs.sh`
2. **LaunchServices registration:**
   ```bash
   lsregister -dump | grep -A 20 ImageMate
   ```
3. **File type tested:** PNG, JPEG, etc.
4. **macOS version:** `sw_vers`
5. **Steps taken:** What you clicked, what happened
