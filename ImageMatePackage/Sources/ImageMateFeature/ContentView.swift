//
//  ContentView.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

public struct ContentView: View {
    @StateObject private var imageViewModel = ImageViewModel()
    @ObservedObject var settings: AppSettings
    @State private var showingFilePicker = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingImageInfo = false
    @State private var eventMonitor: Any?
    @State private var showThumbnails = true
    @State private var thumbnailHideTask: Task<Void, Never>?
    @State private var showingLibrary = false
    @State private var libraryImageUrls: [URL] = []
    @State private var mouseMonitor: Any?
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    
    public init(settings: AppSettings = AppSettings()) {
        self.settings = settings
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            if let image = imageViewModel.currentImage {
                VStack(spacing: 0) {
                    // Main image viewer
                    GeometryReader { geometry in
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(dragGesture)
                            .gesture(magnificationGesture)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .animation(.spring(response: 0.3), value: scale)
                            .animation(.spring(response: 0.3), value: offset)
                    }
                    .frame(maxHeight: shouldShowThumbnails && settings.thumbnailDisplayMode == .alwaysShow ? .infinity : nil)
                    
                    // Thumbnail strip (positioned at bottom, may overlay or push up content)
                    if shouldShowThumbnails {
                        thumbnailStripView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // Top toolbar (overlay)
                VStack {
                    HStack {
                        // File info
                        if let fileName = imageViewModel.currentFileName {
                            Text(fileName)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Zoom controls
                        HStack(spacing: 8) {
                            Button(action: { withAnimation { zoomOut() } }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Text(String(format: "%.0f%%", scale * 100))
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(minWidth: 50)
                            
                            Button(action: { withAnimation { zoomIn() } }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { withAnimation { resetZoom() } }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        
                        // Action buttons
                        Button(action: { showingImageInfo.toggle() }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // Image info panel (overlay)
                if showingImageInfo {
                    HStack(spacing: 0) {
                        // Tap outside to dismiss
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    showingImageInfo = false
                                }
                            }
                        
                        ImageInfoView(
                            image: image,
                            fileName: imageViewModel.currentFileName ?? "",
                            fileUrl: imageViewModel.currentFileUrl,
                            onClose: {
                                withAnimation {
                                    showingImageInfo = false
                                }
                            }
                        )
                        .transition(.move(edge: .trailing))
                    }
                }
                
            } else {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("No Image Loaded")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Drag and drop an image here or click to open")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Button("Open Image") {
                        openImage()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyPress(event: event)
            }
            
            // Add mouse move tracking to show thumbnails when cursor moves to bottom
            mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [self] event in
                self.handleMouseMove(event: event)
                return event
            }
            
            // Listen for menu-triggered open image action
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenImageFromMenu"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    openImage()
                }
            }
            
            // Listen for menu-triggered export action
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ExportImageFromMenu"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    exportImage()
                }
            }
            
            // Listen for URL opening from Finder
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenURLFromFinder"),
                object: nil,
                queue: .main
            ) { [weak imageViewModel] notification in
                Logger.imageOperations.info("🎯 ContentView: Received OpenURLFromFinder notification")
                guard let userInfo = notification.userInfo,
                      let url = userInfo["url"] as? URL else {
                    Logger.imageOperations.error("❌ No URL in notification userInfo")
                    return
                }
                
                Logger.imageOperations.info("📥 ContentView: Processing URL: \(url.path)")
                Task { @MainActor [weak imageViewModel] in
                    guard let imageViewModel else {
                        Logger.imageOperations.error("❌ ImageViewModel is nil")
                        return
                    }
                    self.handleFinderOpen(url: url, imageViewModel: imageViewModel)
                }
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
            
            if let monitor = mouseMonitor {
                NSEvent.removeMonitor(monitor)
            }
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("OpenImageFromMenu"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ExportImageFromMenu"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("OpenURLFromFinder"), object: nil)
        }
        .onChange(of: imageViewModel.currentIndex) {
            resetThumbnailAutoHide()
            resizeWindowToFitImage()
        }
        .onChange(of: imageViewModel.imageUrls) {
            resetThumbnailAutoHide()
            resizeWindowToFitImage()
        }
        .onChange(of: imageViewModel.currentImage) {
            // Trigger resize when image actually loads (not just URL changes)
            if imageViewModel.currentImage != nil {
                resizeWindowToFitImage()
            }
        }
        .onChange(of: settings.autoResizeWindow) {
            if settings.autoResizeWindow {
                resizeWindowToFitImage()
            }
        }
        .onChange(of: settings.thumbnailDisplayMode) {
            if settings.autoResizeWindow {
                // Re-calculate window size when thumbnail mode changes
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay for layout to settle
                    resizeWindowToFitImage()
                }
            }
        }
        .sheet(isPresented: $showingLibrary) {
            libraryView
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var libraryView: some View {
        ImageLibraryView(
            imageUrls: libraryImageUrls,
            onSelect: { selectedIndex in
                showingLibrary = false
                imageViewModel.loadImages(from: libraryImageUrls, startingAt: selectedIndex)
                resetZoom()
            },
            onCancel: {
                showingLibrary = false
                libraryImageUrls = []
            }
        )
        .frame(minWidth: 800, minHeight: 600)
    }
    private var shouldShowThumbnails: Bool {
        guard imageViewModel.imageUrls.count > 1 else { return false }
        
        switch settings.thumbnailDisplayMode {
        case .alwaysShow:
            return true
        case .autoHide:
            return showThumbnails
        }
    }
    
    private var thumbnailStripView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(imageViewModel.imageUrls.enumerated()), id: \.offset) { index, url in
                    ThumbnailView(
                        url: url,
                        isSelected: index == imageViewModel.currentIndex
                    )
                    .onTapGesture {
                        imageViewModel.selectImage(at: index)
                        resetZoom()
                        resetThumbnailAutoHide()
                    }
                }
            }
            .padding()
        }
        .frame(height: 100)
        .background(.ultraThinMaterial)
        .onHover { hovering in
            if settings.thumbnailDisplayMode == .autoHide {
                if hovering {
                    thumbnailHideTask?.cancel()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showThumbnails = true
                    }
                } else {
                    resetThumbnailAutoHide()
                }
            }
        }
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / scale
                scale = max(0.1, min(scale * delta, 10))
            }
    }
    
    // MARK: - Actions
    
    public func openImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true  // Allow folder selection
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "Select images or a folder. All images will be loaded."
        panel.prompt = "Open"
        
        if panel.runModal() == .OK {
            var imageUrls: [URL] = []
            var directoriesToAccess: Set<URL> = []
            var isFolderSelection = false
            
            for url in panel.urls {
                // Start accessing security-scoped resource immediately for the selected URL
                _ = url.startAccessingSecurityScopedResource()
                
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // User selected a folder - collect images for library view
                        isFolderSelection = true
                        Logger.imageOperations.info("User selected folder: \(url.path)")
                        directoriesToAccess.insert(url)
                        
                        // Grant access to ViewModel for later use
                        imageViewModel.grantDirectoryAccess(url)
                        
                        if let enumerator = FileManager.default.enumerator(
                            at: url,
                            includingPropertiesForKeys: [.isRegularFileKey],
                            options: [.skipsHiddenFiles]
                        ) {
                            for case let fileURL as URL in enumerator {
                                if let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                                   resourceValues.isRegularFile == true,
                                   isImageFile(fileURL) {
                                    imageUrls.append(fileURL)
                                }
                            }
                        }
                        
                        Logger.imageOperations.info("Found \(imageUrls.count) images in folder")
                    } else {
                        // User selected individual file(s)
                        imageUrls.append(url)
                        let parentDir = url.deletingLastPathComponent()
                        directoriesToAccess.insert(parentDir)
                        
                        // Grant access to parent directory
                        _ = parentDir.startAccessingSecurityScopedResource()
                        imageViewModel.grantDirectoryAccess(parentDir)
                    }
                }
            }
            
            if !imageUrls.isEmpty {
                if isFolderSelection {
                    // Show library view for folder selection
                    libraryImageUrls = imageUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
                    showingLibrary = true
                } else {
                    // Load images directly for individual file selection
                    imageViewModel.loadImages(from: imageUrls)
                    resetZoom()
                    resizeWindowToFitImage()
                }
            } else {
                Logger.imageOperations.warning("No images found in selected location(s)")
            }
        }
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
    
    // MARK: - Export
    
    public func exportImage() {
        guard let image = imageViewModel.currentImage else {
            Logger.imageOperations.warning("No image to export")
            return
        }
        
        let panel = NSSavePanel()
        panel.title = "Export Image"
        panel.prompt = "Export"
        
        // Default filename derived from current file
        let baseName: String
        if let currentName = imageViewModel.currentFileName {
            baseName = (currentName as NSString).deletingPathExtension
        } else {
            baseName = "Untitled"
        }
        panel.nameFieldStringValue = "\(baseName).heic"
        
        // Build allowed types from ExportFormat
        panel.allowedContentTypes = ExportFormat.allCases.map(\.utType)
        
        // Use an accessory view for format selection
        let formatPicker = ExportFormatAccessoryView { selectedFormat in
            panel.allowedContentTypes = [selectedFormat.utType]
            panel.nameFieldStringValue = "\(baseName).\(selectedFormat.fileExtension)"
        }
        let hostingView = NSHostingView(rootView: formatPicker)
        hostingView.frame = NSRect(x: 0, y: 0, width: 250, height: 50)
        panel.accessoryView = hostingView
        
        if panel.runModal() == .OK, let url = panel.url {
            // Determine format from the file extension
            let ext = url.pathExtension.lowercased()
            let format: ExportFormat
            switch ext {
            case "heic", "heif":
                format = .heic
            case "jpg", "jpeg":
                format = .jpeg
            case "png":
                format = .png
            case "tiff", "tif":
                format = .tiff
            default:
                format = .heic
            }
            
            do {
                try ImageExporter.export(image, to: url, format: format)
                Logger.imageOperations.info("Image exported to \(url.path)")
            } catch {
                Logger.imageOperations.error("Export failed: \(error.localizedDescription)")
                exportErrorMessage = error.localizedDescription
                showExportError = true
            }
        }
    }
    
    private func handleFinderOpen(url: URL, imageViewModel: ImageViewModel) {
        Logger.imageOperations.info("🎯 handleFinderOpen called with URL: \(url.path)")
        
        // Start accessing security-scoped resource
        let hasAccess = url.startAccessingSecurityScopedResource()
        Logger.imageOperations.info("🔐 Security-scoped resource access: \(hasAccess)")
        
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        Logger.imageOperations.info("📁 File exists: \(fileExists), Is directory: \(isDirectory.boolValue)")
        
        if fileExists {
            if isDirectory.boolValue {
                // User opened a folder - scan and show library
                Logger.imageOperations.info("📂 Processing as folder")
                imageViewModel.grantDirectoryAccess(url)
                
                var imageUrls: [URL] = []
                if let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let fileURL as URL in enumerator {
                        if let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                           resourceValues.isRegularFile == true,
                           isImageFile(fileURL) {
                            imageUrls.append(fileURL)
                        }
                    }
                }
                
                Logger.imageOperations.info("🖼️ Found \(imageUrls.count) images in folder")
                if !imageUrls.isEmpty {
                    libraryImageUrls = imageUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
                    showingLibrary = true
                    Logger.imageOperations.info("✅ Showing library view")
                } else {
                    Logger.imageOperations.warning("⚠️ No images found in folder")
                }
            } else {
                // User opened an image file
                Logger.imageOperations.info("🖼️ Processing as single image file")
                let parentDir = url.deletingLastPathComponent()
                Logger.imageOperations.info("📂 Parent directory: \(parentDir.path)")
                _ = parentDir.startAccessingSecurityScopedResource()
                imageViewModel.grantDirectoryAccess(parentDir)
                imageViewModel.loadImages(from: [url])
                resetZoom()
                resizeWindowToFitImage()
                Logger.imageOperations.info("✅ Image loaded successfully")
            }
        } else {
            Logger.imageOperations.error("❌ File does not exist at path: \(url.path)")
        }
    }
    
    private func zoomIn() {
        scale = min(scale * 1.2, 10)
    }
    
    private func zoomOut() {
        scale = max(scale / 1.2, 0.1)
    }
    
    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
    }
    
    private func resizeWindowToFitImage() {
        guard settings.autoResizeWindow,
              let image = imageViewModel.currentImage,
              let window = NSApplication.shared.windows.first else {
            return
        }
        
        Logger.ui.info("Auto-resizing window for image size: \(image.size.width)x\(image.size.height)")
        
        // Get the screen's visible frame (excluding menu bar and dock)
        guard let screen = window.screen ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        
        // Calculate maximum available size (leave some padding)
        let maxWidth = visibleFrame.width * 0.9
        let maxHeight = visibleFrame.height * 0.9
        
        // Account for thumbnail height if always showing
        let thumbnailHeight: CGFloat = (imageViewModel.imageUrls.count > 1 && settings.thumbnailDisplayMode == .alwaysShow) ? 120 : 0
        let toolbarHeight: CGFloat = 80 // Approximate height for top toolbar
        let availableHeight = maxHeight - thumbnailHeight - toolbarHeight
        
        // Calculate the window size to fit the image
        var newWidth = image.size.width
        var newHeight = image.size.height
        
        // Scale down if image is too large
        if newWidth > maxWidth || newHeight > availableHeight {
            let widthRatio = maxWidth / newWidth
            let heightRatio = availableHeight / newHeight
            let scale = min(widthRatio, heightRatio)
            
            newWidth *= scale
            newHeight *= scale
        }
        
        // Add space for thumbnails and toolbar
        newHeight += thumbnailHeight + toolbarHeight
        
        // Ensure minimum window size
        newWidth = max(newWidth, 600)
        newHeight = max(newHeight, 400)
        
        // Calculate new window frame centered on screen
        let newOriginX = visibleFrame.origin.x + (visibleFrame.width - newWidth) / 2
        let newOriginY = visibleFrame.origin.y + (visibleFrame.height - newHeight) / 2
        
        let newFrame = NSRect(
            x: newOriginX,
            y: newOriginY,
            width: newWidth,
            height: newHeight
        )
        
        // Animate the window resize
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
        
        Logger.ui.debug("Window resized to: \(newWidth)x\(newHeight)")
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Logger.imageOperations.info("🎯 handleDrop: Received \(providers.count) providers")
        
        // Use a thread-safe wrapper class to avoid concurrency warnings
        final class ThreadSafeURLArray: @unchecked Sendable {
            private var urls: [URL] = []
            private let lock = NSLock()
            
            func append(_ url: URL) {
                lock.lock()
                defer { lock.unlock() }
                urls.append(url)
            }
            
            func getAll() -> [URL] {
                lock.lock()
                defer { lock.unlock() }
                return urls
            }
        }
        
        let collectedUrls = ThreadSafeURLArray()
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }
                
                if let error = error {
                    Logger.imageOperations.error("❌ Drop error: \(error.localizedDescription)")
                    return
                }
                
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Logger.imageOperations.info("📄 Dropped file: \(url.path)")
                    // Start accessing security-scoped resource for sandboxed apps
                    _ = url.startAccessingSecurityScopedResource()
                    collectedUrls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            let urls = collectedUrls.getAll()
            Logger.imageOperations.info("📥 Processing \(urls.count) dropped files")
            if !urls.isEmpty {
                // Grant directory access for parent folder
                if let firstUrl = urls.first {
                    let parentDir = firstUrl.deletingLastPathComponent()
                    _ = parentDir.startAccessingSecurityScopedResource()
                    self.imageViewModel.grantDirectoryAccess(parentDir)
                }
                self.imageViewModel.loadImages(from: urls)
                self.resetZoom()
                self.resizeWindowToFitImage()
                Logger.imageOperations.info("✅ Dropped images loaded successfully")
            }
        }
        
        return true
    }
    
    private func handleKeyPress(event: NSEvent) -> NSEvent? {
        Logger.ui.debug("Key pressed: keyCode=\(event.keyCode)")
        switch event.keyCode {
        case 123: // Left arrow
            Logger.ui.info("Left arrow pressed - going to previous image")
            imageViewModel.previousImage()
            resetZoom()
            resetThumbnailAutoHide()
        case 124: // Right arrow
            Logger.ui.info("Right arrow pressed - going to next image")
            imageViewModel.nextImage()
            resetZoom()
            resetThumbnailAutoHide()
        case 53: // Escape
            Logger.ui.info("Escape pressed")
            if showingImageInfo {
                // Close info panel first if it's open
                withAnimation {
                    showingImageInfo = false
                }
            } else {
                // Otherwise reset zoom
                resetZoom()
            }
        default:
            return event
        }
        return nil
    }
    
    private func resetThumbnailAutoHide() {
        guard settings.thumbnailDisplayMode == .autoHide else { return }
        
        // Cancel any existing hide task
        thumbnailHideTask?.cancel()
        
        // Show thumbnails
        withAnimation(.easeInOut(duration: 0.2)) {
            showThumbnails = true
        }
        
        // Schedule auto-hide after 2 seconds
        thumbnailHideTask = Task {
            try? await Task.sleep(for: .seconds(2))
            
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showThumbnails = false
                    }
                }
            }
        }
    }
    
    private func handleMouseMove(event: NSEvent) {
        // Only track mouse for auto-hide mode
        guard settings.thumbnailDisplayMode == .autoHide,
              imageViewModel.imageUrls.count > 1 else {
            return
        }
        
        // Get the window and mouse location
        guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        // Get mouse position in window coordinates
        let mouseLocation = window.mouseLocationOutsideOfEventStream
        
        // Define a threshold distance from bottom (e.g., 100 points)
        let bottomThreshold: CGFloat = 100
        
        // If mouse is near the bottom of the window, show thumbnails
        if mouseLocation.y <= bottomThreshold {
            thumbnailHideTask?.cancel()
            withAnimation(.easeInOut(duration: 0.2)) {
                showThumbnails = true
            }
        } else if showThumbnails {
            // If mouse moves away from bottom, start auto-hide timer
            resetThumbnailAutoHide()
        }
    }
}

// MARK: - Thumbnail View

struct ThumbnailView: View {
    let url: URL
    let isSelected: Bool
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .shadow(radius: 4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: url) {
                let size = CGSize(width: 160, height: 160)
                let thumbnail = image.resized(to: size)
                DispatchQueue.main.async {
                    self.thumbnail = thumbnail
                }
            }
        }
    }
}

// MARK: - Image Info View

struct ImageInfoView: View {
    let image: NSImage
    let fileName: String
    let fileUrl: URL?
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Image Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            
            Divider()
            
            InfoRow(label: "Name", value: fileName)
            InfoRow(label: "Size", value: "\(Int(image.size.width)) × \(Int(image.size.height))")
            
            if let fileUrl = fileUrl {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileUrl.path),
                   let fileSize = attributes[.size] as? Int64 {
                    InfoRow(label: "File Size", value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                }
                
                InfoRow(label: "Path", value: fileUrl.path)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
