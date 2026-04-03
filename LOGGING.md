# How to Collect Logs from ImageMate

ImageMate now uses Apple's unified logging system (OSLog) which provides powerful, efficient logging capabilities. Here are several methods to collect and view logs:

## Method 1: Console App (Easiest - GUI)

1. **Open Console.app**:
   ```bash
   open /System/Applications/Utilities/Console.app
   ```

2. **Filter logs for ImageMate**:
   - In the search bar at the top right, enter: `subsystem:com.imagemate.app`
   - Or filter by process: `process:ImageMate`
   - Or search for specific text: `"Loading image"` or `"Next image"`

3. **View logs in real-time**:
   - Click "Start" button in the toolbar to stream logs
   - Open ImageMate and perform actions
   - Logs will appear in real-time

4. **Save logs**:
   - Select the logs you want
   - Right-click → "Save Selected Messages..."
   - Or File → Save Selection

## Method 2: Command Line - log stream (Real-time)

View logs in real-time from Terminal:

```bash
# Stream all ImageMate logs
log stream --predicate 'subsystem == "com.imagemate.app"' --level debug

# Stream only image operations
log stream --predicate 'subsystem == "com.imagemate.app" AND category == "imageOperations"' --level debug

# Stream UI events
log stream --predicate 'subsystem == "com.imagemate.app" AND category == "ui"' --level debug

# Stream with color and process info
log stream --predicate 'subsystem == "com.imagemate.app"' --level debug --style compact --color auto
```

**Tips**:
- Press `Ctrl+C` to stop streaming
- Redirect to file: `log stream ... > imagemate.log`

## Method 3: Command Line - log show (Historical)

Query historical logs (logs are persisted by the system):

```bash
# Show logs from the last hour
log show --predicate 'subsystem == "com.imagemate.app"' --last 1h --info

# Show logs from the last 30 minutes with debug level
log show --predicate 'subsystem == "com.imagemate.app"' --last 30m --debug

# Show logs since a specific time
log show --predicate 'subsystem == "com.imagemate.app"' --start "2025-10-20 18:00:00"

# Export to file
log show --predicate 'subsystem == "com.imagemate.app"' --last 1h --debug > imagemate-logs.txt

# Search for specific events
log show --predicate 'subsystem == "com.imagemate.app" AND eventMessage CONTAINS "arrow"' --last 1h
```

## Method 4: Using log collect (Full System Logs)

Create a diagnostic archive (useful for bug reports):

```bash
# Collect logs from the last hour
sudo log collect --last 1h --output ~/Desktop/imagemate-logs.logarchive

# View the archive
log show ~/Desktop/imagemate-logs.logarchive --predicate 'subsystem == "com.imagemate.app"'
```

## Method 5: Xcode Console (During Development)

If you run the app from Xcode:

1. **Build and Run** from Xcode (`Cmd+R`)
2. View logs in **Debug Area** (bottom panel)
3. Filter console output by typing in the search box
4. Right-click in console → "Save Console Output..." to export

## Log Categories in ImageMate

The app uses three log categories:

1. **`general`** - General app events
   ```bash
   log stream --predicate 'subsystem == "com.imagemate.app" AND category == "general"'
   ```

2. **`imageOperations`** - Image loading and management
   ```bash
   log stream --predicate 'subsystem == "com.imagemate.app" AND category == "imageOperations"'
   ```

3. **`ui`** - UI events (key presses, navigation)
   ```bash
   log stream --predicate 'subsystem == "com.imagemate.app" AND category == "ui"'
   ```

## Example: Debug Arrow Key Navigation

To see what happens when you press arrow keys:

```bash
# Terminal 1: Start log streaming
log stream --predicate 'subsystem == "com.imagemate.app"' --level debug --style compact

# Terminal 2: Open the app
open /Users/kenkuang/Library/Developer/Xcode/DerivedData/ImageMate-ctrbivcgrnmrpubrugtoorgwmnqn/Build/Products/Release/ImageMate.app

# Now use arrow keys in the app and watch the logs in Terminal 1
```

## Example: Debug Image Loading

```bash
log stream --predicate 'subsystem == "com.imagemate.app" AND category == "imageOperations"' --level debug
```

You'll see logs like:
- "Loading images from N URLs"
- "Filtered to N image files"
- "Single image detected, scanning directory: /path/to/dir"
- "Found N images in directory"
- "Loading image: filename.jpg"
- "Successfully loaded image: filename.jpg, size: 1920x1080"

## Troubleshooting

### No logs appearing?

1. **Check the app is running**:
   ```bash
   ps aux | grep ImageMate
   ```

2. **Check if logs are being created**:
   ```bash
   log show --predicate 'process == "ImageMate"' --last 5m
   ```

3. **Ensure you're filtering correctly**:
   ```bash
   # Try broader search
   log stream --predicate 'processImagePath CONTAINS "ImageMate"'
   ```

### Finding the bundle ID

```bash
# Get the actual bundle ID
mdls -name kMDItemCFBundleIdentifier /path/to/ImageMate.app
```

## Quick Reference Card

```bash
# Real-time logs (recommended for debugging)
log stream --predicate 'subsystem == "com.imagemate.app"' --level debug

# Last 30 minutes of logs
log show --predicate 'subsystem == "com.imagemate.app"' --last 30m --debug

# Save logs to file
log show --predicate 'subsystem == "com.imagemate.app"' --last 1h --debug > ~/Desktop/imagemate.log

# Open Console app
open /System/Applications/Utilities/Console.app
```

## Log Levels

- **debug**: Detailed debugging information (most verbose)
- **info**: Informational messages about normal operations
- **default**: Default level (info + important notices)
- **error**: Error conditions
- **fault**: Critical errors

Use `--level debug` to see all logs including verbose debugging information.
