# ImageMate Features

## Settings

Access all settings through the macOS menu bar:
- Go to **ImageMate → Settings...** (or press `⌘,`)
- Settings window can be opened/closed as needed
- All preferences are automatically saved

## Menu Bar

The app provides standard macOS menu items:

### File Menu
- **Open Images or Folder...** (`⌘O`) - Opens file picker to select:
  - **Individual images** - Select one or more image files
  - **Entire folder** - Select a folder to load all images within it
  - All images are automatically loaded and ready to browse
  - Supports drag & drop as an alternative
- **Export As...** (`⌘⇧S`) - Convert and save the current image:
  - **HEIC** - High-efficiency format (default, smaller file size)
  - **JPEG** - Universal compatibility
  - **PNG** - Lossless with transparency
  - **TIFF** - Lossless, high quality

### ImageMate Menu
- **Settings...** (`⌘,`) - Opens the settings window
- Standard About, Hide, Quit commands

## Auto-Resize Window

The app automatically adjusts the window size to fit each image (enabled by default).

### How It Works

1. **Automatic Sizing**: Window automatically resizes to show images at their actual size
2. **Smart Scaling**: Images larger than the screen are scaled down proportionally
3. **Enabled by Default**: Works like macOS Preview - images appear at proper size immediately
4. **Responsive**: Window size adjusts when:

### User Control

Access the settings via the menu bar:
- **ImageMate → Settings...** (or press `⌘,`)
- Toggle "Auto-Resize Window" on/off (ON by default)
- Setting saved automatically

**Why is this ON by default?**
Images appear at their proper size, matching the behavior of macOS Preview. Turn it off if you prefer a fixed window size.

### Technical Details

- Respects screen boundaries (90% of visible screen area)
- Accounts for thumbnail height when in "Always Show" mode
- Smooth animations (0.3s duration with ease-in-ease-out)
- Minimum window size: 600x400
- Centers window on screen after resize

### Settings Panel

The settings window includes two sections:

1. **Thumbnail Display**
   - Always Show (Resize View)
   - Auto Hide (2-second timer)

2. **Window Behavior**
   - Auto-Resize Window toggle

Access via: **ImageMate → Settings...** or `⌘,`

## Other Features

### Thumbnail Display Modes

- **Always Show**: Thumbnails remain visible, image view is resized
- **Auto Hide**: Thumbnails automatically hide after 2 seconds of inactivity

### Image Navigation

- **Arrow Keys**: ← → to navigate between images
- **Thumbnails**: Click any thumbnail to jump to that image
- **Drag & Drop**: Drop image files or entire folders
- **Menu**: File → Open Images or Folder... (⌘O)
  - Select individual images or an entire folder
  - Recursively loads all images from selected folder

### Image Export / Conversion

Convert any loaded image to a different format:
- **File → Export As...** (`⌘⇧S`)
- Choose from HEIC, JPEG, PNG, or TIFF via a segmented picker
- HEIC and JPEG use 85% quality by default for good size/quality balance
- Uses Apple's native ImageIO for maximum compatibility

### Zoom & Pan

- **Pinch Gesture**: Zoom in/out on trackpad
- **Drag**: Pan around zoomed images
- **Zoom Controls**: +/- buttons in toolbar
- **Reset**: Click reset button to return to 100%

### Image Information

View detailed image information with the info panel:
- Click the info button (ℹ️) to open
- **Multiple ways to close:**
  - Click the X button in the panel
  - Click anywhere outside the panel
  - Press ESC key
- Shows: filename, dimensions, file size, file path
- Path is selectable for copying

### Keyboard Shortcuts

- `←` Previous image
- `→` Next image
- `ESC` Close info panel (if open) or reset zoom
- `⌘⇧S` Export current image as HEIC/JPEG/PNG/TIFF
- `⌘O` Open image (file picker)
- `⌘,` Open settings window
- `ℹ️` Toggle image info panel
