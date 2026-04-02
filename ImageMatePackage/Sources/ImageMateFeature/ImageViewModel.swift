//
//  ImageViewModel.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI
import AppKit
import OSLog

@MainActor
public class ImageViewModel: ObservableObject {
    @Published public var currentImage: NSImage?
    @Published public var currentIndex: Int = 0
    @Published public var imageUrls: [URL] = []
    /// Set when directory scan fails for a single-file open — the UI
    /// should prompt the user to grant access to this directory.
    @Published public var pendingDirectoryAccess: URL?
    
    private var accessingDirectories: Set<URL> = []
    
    public var currentFileName: String? {
        guard currentIndex < imageUrls.count else { return nil }
        return imageUrls[currentIndex].lastPathComponent
    }
    
    public var currentFileUrl: URL? {
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
        // Stop accessing all directories
        for directory in accessingDirectories {
            directory.stopAccessingSecurityScopedResource()
        }
    }
    
    public func loadImages(from urls: [URL], startingAt startIndex: Int? = nil, grantedDirectory: URL? = nil) {
        Logger.imageOperations.info("Loading images from \(urls.count) URLs")
        
        let validExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg"]
        
        // Filter only image files
        var imageUrls = urls.filter { url in
            return validExtensions.contains(url.pathExtension.lowercased())
        }
        
        Logger.imageOperations.debug("Filtered to \(imageUrls.count) image files")
        
        guard !imageUrls.isEmpty else { 
            Logger.imageOperations.warning("No valid image files found")
            return 
        }
        
        // If startingAt is provided, skip directory scanning and use the provided list
        if let startIndex = startIndex {
            // Sort by name
            self.imageUrls = imageUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
            Logger.imageOperations.info("Using provided image list with \(self.imageUrls.count) images, starting at index \(startIndex)")
            
            // Set starting index
            self.currentIndex = min(startIndex, self.imageUrls.count - 1)
            Logger.imageOperations.info("Set current index to \(self.currentIndex)")
            
            loadCurrentImage()
            return
        }
        
        // If only one image is loaded, try to load all images from the same directory
        if imageUrls.count == 1, let firstUrl = imageUrls.first {
            // Use the pre-granted directory if available, otherwise derive from file URL
            let directory = grantedDirectory ?? firstUrl.deletingLastPathComponent()
            Logger.imageOperations.info("Single image detected, scanning directory: \(directory.path)")
            
            // Only start security-scoped access on the file if no directory was pre-granted
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
                // Signal the UI to prompt the user for folder access
                self.pendingDirectoryAccess = directory
            }
        }
        
        // Sort by name
        self.imageUrls = imageUrls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        Logger.imageOperations.info("Final image list has \(self.imageUrls.count) images")
        
        // Log all image names for debugging
        if self.imageUrls.count <= 10 {
            for (index, url) in self.imageUrls.enumerated() {
                Logger.imageOperations.debug("  [\(index)]: \(url.lastPathComponent)")
            }
        }
        
        // Find the index of the originally selected image (compare by lastPathComponent
        // to handle URL normalization differences between Finder and FileManager)
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
    /// Called from the UI after NSOpenPanel or bookmark restore succeeds.
    public func rescanDirectory(_ directory: URL) {
        pendingDirectoryAccess = nil
        grantDirectoryAccess(directory)
        
        guard let currentUrl = imageUrls.first else { return }
        loadImages(from: [currentUrl], grantedDirectory: directory)
    }
    
    public func selectImage(at index: Int) {
        guard index >= 0 && index < imageUrls.count else { return }
        Logger.imageOperations.debug("Selecting image at index \(index)")
        currentIndex = index
        loadCurrentImage()
    }
    
    public func nextImage() {
        guard !imageUrls.isEmpty else { return }
        let oldIndex = currentIndex
        currentIndex = (currentIndex + 1) % imageUrls.count
        Logger.ui.info("Next image: \(oldIndex) -> \(self.currentIndex)")
        loadCurrentImage()
    }
    
    public func previousImage() {
        guard !imageUrls.isEmpty else { return }
        let oldIndex = currentIndex
        currentIndex = (currentIndex - 1 + imageUrls.count) % imageUrls.count
        Logger.ui.info("Previous image: \(oldIndex) -> \(self.currentIndex)")
        loadCurrentImage()
    }
    
    private func loadCurrentImage() {
        guard currentIndex < imageUrls.count else { 
            Logger.imageOperations.error("Current index \(self.currentIndex) out of bounds (count: \(self.imageUrls.count))")
            return 
        }
        let url = imageUrls[currentIndex]
        Logger.imageOperations.info("Loading image: \(url.lastPathComponent)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: url) {
                Logger.imageOperations.debug("Successfully loaded image: \(url.lastPathComponent), size: \(image.size.width)x\(image.size.height)")
                DispatchQueue.main.async {
                    self.currentImage = image
                }
            } else {
                Logger.imageOperations.error("Failed to load image: \(url.lastPathComponent)")
            }
        }
    }
}
