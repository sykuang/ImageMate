//
//  ImageViewModel.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI
import AppKit
import ImageIO
import OSLog

@MainActor
public class ImageViewModel: ObservableObject {
    @Published public var currentImage: NSImage?
    @Published public var currentIndex: Int = 0
    @Published public var imageUrls: [URL] = []
    /// Set when directory scan fails for a single-file open — the UI
    /// should prompt the user to grant access to this directory.
    @Published public var pendingDirectoryAccess: URL?

    // MARK: - APNG Frame Mode

    @Published public var isCurrentImageAPNG: Bool = false
    @Published public var isFrameMode: Bool = false
    public private(set) var frameSource: APNGFrameSource?
    private var savedFileIndex: Int?

    /// Number of items visible in the thumbnail strip (frames or files).
    public var displayItemCount: Int {
        isFrameMode ? (frameSource?.frameCount ?? 0) : imageUrls.count
    }

    /// Title shown in the toolbar — filename, or filename + frame indicator.
    public var currentDisplayTitle: String? {
        if isFrameMode, let source = frameSource {
            return "\(source.sourceURL.lastPathComponent) — Frame \(currentIndex + 1)/\(source.frameCount)"
        }
        return currentFileName
    }
    
    private var accessingDirectories: Set<URL> = []
    
    public var currentFileName: String? {
        guard currentIndex < imageUrls.count else { return nil }
        return imageUrls[currentIndex].lastPathComponent
    }
    
    public var currentFileUrl: URL? {
        if isFrameMode { return frameSource?.sourceURL }
        guard currentIndex < imageUrls.count else { return nil }
        return imageUrls[currentIndex]
    }
    
    public init() {}
    
    public func grantDirectoryAccess(_ directory: URL) {
        if !accessingDirectories.contains(directory) {
            _ = directory.startAccessingSecurityScopedResource()
            accessingDirectories.insert(directory)
            Logger.imageOperations.debug("Granted access to directory: \(directory.path)")
        }
    }
    
    deinit {
        for directory in accessingDirectories {
            directory.stopAccessingSecurityScopedResource()
        }
    }
    
    public func loadImages(from urls: [URL], startingAt startIndex: Int? = nil, grantedDirectory: URL? = nil) {
        // Exit frame mode when loading a new set of images
        if isFrameMode { exitFrameMode() }

        Logger.imageOperations.info("Loading images from \(urls.count) URLs")
        
        let validExtensions = ["jpg", "jpeg", "png", "apng", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg"]
        
        var imageUrls = urls.filter { url in
            return validExtensions.contains(url.pathExtension.lowercased())
        }
        
        Logger.imageOperations.debug("Filtered to \(imageUrls.count) image files")
        
        guard !imageUrls.isEmpty else { 
            Logger.imageOperations.warning("No valid image files found")
            return 
        }
        
        if let startIndex = startIndex {
            self.imageUrls = imageUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
            Logger.imageOperations.info("Using provided image list with \(self.imageUrls.count) images, starting at index \(startIndex)")
            
            self.currentIndex = min(startIndex, self.imageUrls.count - 1)
            Logger.imageOperations.info("Set current index to \(self.currentIndex)")
            
            loadCurrentImage()
            return
        }
        
        if imageUrls.count == 1, let firstUrl = imageUrls.first {
            let directory = grantedDirectory ?? firstUrl.deletingLastPathComponent()
            Logger.imageOperations.info("Single image detected, scanning directory: \(directory.path)")
            
            let accessing: Bool
            if grantedDirectory == nil {
                accessing = firstUrl.startAccessingSecurityScopedResource()
                Logger.imageOperations.debug("Security-scoped access on file: \(accessing)")
            } else {
                accessing = false
                Logger.imageOperations.debug("Using pre-granted directory access")
            }
            defer {
                if accessing {
                    firstUrl.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                Logger.imageOperations.info("Directory contains \(contents.count) total files")
                
                let allImages = contents.filter { url in
                    let ext = url.pathExtension.lowercased()
                    let isValid = validExtensions.contains(ext)
                    if !isValid {
                        Logger.imageOperations.debug("Skipping file: \(url.lastPathComponent) (extension: \(ext))")
                    }
                    return isValid
                }
                Logger.imageOperations.info("Found \(allImages.count) images in directory")
                
                if !allImages.isEmpty {
                    Logger.imageOperations.debug("Replacing single image with \(allImages.count) images from directory")
                    imageUrls = allImages
                } else {
                    Logger.imageOperations.warning("No images found in directory despite scanning")
                }
            } catch {
                Logger.imageOperations.error("Failed to scan directory '\(directory.path)': \(error.localizedDescription)")
                Logger.imageOperations.error("Directory scan error details: \(error)")
                self.pendingDirectoryAccess = directory
            }
        }
        
        self.imageUrls = imageUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        Logger.imageOperations.info("Final image list has \(self.imageUrls.count) images")
        
        if self.imageUrls.count <= 10 {
            for (index, url) in self.imageUrls.enumerated() {
                Logger.imageOperations.debug("  [\(index)]: \(url.lastPathComponent)")
            }
        }
        
        if let firstUrl = urls.first {
            let targetName = firstUrl.lastPathComponent
            if let index = self.imageUrls.firstIndex(where: { $0.lastPathComponent == targetName }) {
                self.currentIndex = index
                Logger.imageOperations.info("Set current index to \(index) for \(targetName)")
            } else {
                self.currentIndex = 0
                Logger.imageOperations.info("Could not find \(targetName) in list, set current index to 0")
            }
        } else {
            self.currentIndex = 0
            Logger.imageOperations.info("Set current index to 0")
        }
        
        loadCurrentImage()
    }
    
    /// Re-scan the directory after the user grants folder access.
    public func rescanDirectory(_ directory: URL) {
        pendingDirectoryAccess = nil
        grantDirectoryAccess(directory)
        
        guard let currentUrl = imageUrls.first else { return }
        loadImages(from: [currentUrl], grantedDirectory: directory)
    }
    
    public func selectImage(at index: Int) {
        if isFrameMode {
            guard let source = frameSource, index >= 0, index < source.frameCount else { return }
            Logger.imageOperations.debug("Selecting frame \(index)")
            currentIndex = index
            loadCurrentFrame()
        } else {
            guard index >= 0, index < imageUrls.count else { return }
            Logger.imageOperations.debug("Selecting image at index \(index)")
            currentIndex = index
            loadCurrentImage()
        }
    }
    
    public func nextImage() {
        if isFrameMode {
            guard let source = frameSource else { return }
            let oldIndex = currentIndex
            currentIndex = (currentIndex + 1) % source.frameCount
            Logger.ui.info("Next frame: \(oldIndex) -> \(self.currentIndex)")
            loadCurrentFrame()
        } else {
            guard !imageUrls.isEmpty else { return }
            let oldIndex = currentIndex
            currentIndex = (currentIndex + 1) % imageUrls.count
            Logger.ui.info("Next image: \(oldIndex) -> \(self.currentIndex)")
            loadCurrentImage()
        }
    }
    
    public func previousImage() {
        if isFrameMode {
            guard let source = frameSource else { return }
            let oldIndex = currentIndex
            currentIndex = (currentIndex - 1 + source.frameCount) % source.frameCount
            Logger.ui.info("Previous frame: \(oldIndex) -> \(self.currentIndex)")
            loadCurrentFrame()
        } else {
            guard !imageUrls.isEmpty else { return }
            let oldIndex = currentIndex
            currentIndex = (currentIndex - 1 + imageUrls.count) % imageUrls.count
            Logger.ui.info("Previous image: \(oldIndex) -> \(self.currentIndex)")
            loadCurrentImage()
        }
    }

    // MARK: - Frame Mode

    public func enterFrameMode() {
        guard !isFrameMode,
              let url = currentFileUrl,
              isCurrentImageAPNG else { return }

        Logger.imageOperations.info("Entering APNG frame mode for \(url.lastPathComponent)")

        let fileIndex = currentIndex
        DispatchQueue.global(qos: .userInitiated).async {
            guard let source = APNGFrameSource(url: url) else {
                Logger.imageOperations.error("Failed to create APNGFrameSource for \(url.lastPathComponent)")
                return
            }
            let firstFrame = source.frame(at: 0)

            DispatchQueue.main.async {
                self.savedFileIndex = fileIndex
                self.frameSource = source
                self.isFrameMode = true
                self.currentIndex = 0
                if let firstFrame {
                    self.currentImage = firstFrame
                }
                Logger.imageOperations.info("Frame mode active: \(source.frameCount) frames")
            }
        }
    }

    public func exitFrameMode() {
        guard isFrameMode else { return }
        Logger.imageOperations.info("Exiting APNG frame mode")

        isFrameMode = false
        frameSource = nil

        if let saved = savedFileIndex {
            currentIndex = saved
            savedFileIndex = nil
        }

        loadCurrentImage()
    }

    // MARK: - Private

    private func loadCurrentImage() {
        guard currentIndex < imageUrls.count else { 
            Logger.imageOperations.error("Current index \(self.currentIndex) out of bounds (count: \(self.imageUrls.count))")
            return 
        }
        let url = imageUrls[currentIndex]
        Logger.imageOperations.info("Loading image: \(url.lastPathComponent)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else {
                Logger.imageOperations.error("Failed to read data for \(url.lastPathComponent)")
                return
            }

            guard let image = NSImage(data: data) else {
                Logger.imageOperations.error("Failed to load image: \(url.lastPathComponent)")
                return
            }

            // Detect APNG: multi-frame PNG
            var apng = false
            if let source = CGImageSourceCreateWithData(data as CFData, nil),
               let utType = CGImageSourceGetType(source) as String?,
               utType == "public.png",
               CGImageSourceGetCount(source) > 1 {
                apng = true
            }

            Logger.imageOperations.debug("Loaded \(url.lastPathComponent), size: \(image.size.width)x\(image.size.height), apng: \(apng)")

            DispatchQueue.main.async {
                self.currentImage = image
                self.isCurrentImageAPNG = apng
            }
        }
    }

    private func loadCurrentFrame() {
        guard let source = frameSource else { return }
        let index = currentIndex
        guard index < source.frameCount else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if let image = source.frame(at: index) {
                DispatchQueue.main.async {
                    self.currentImage = image
                }
            }
        }
    }
}
