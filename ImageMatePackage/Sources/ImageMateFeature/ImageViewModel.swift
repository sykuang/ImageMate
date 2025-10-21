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
    
    public func loadImages(from urls: [URL], startingAt startIndex: Int? = nil) {
        Logger.imageOperations.info("Loading images from \(urls.count) URLs")
        
        // Filter only image files
        var imageUrls = urls.filter { url in
            let validExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
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
            let directory = firstUrl.deletingLastPathComponent()
            Logger.imageOperations.debug("Single image detected, scanning directory: \(directory.path)")
            
            // Start accessing the security-scoped resource
            let accessing = firstUrl.startAccessingSecurityScopedResource()
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
                Logger.imageOperations.debug("Directory contains \(contents.count) total files")
                
                let allImages = contents.filter { url in
                    let validExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
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
                Logger.imageOperations.error("Failed to scan directory: \(error.localizedDescription)")
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
        
        // Find the index of the originally selected image
        if let firstUrl = urls.first,
           let index = self.imageUrls.firstIndex(of: firstUrl) {
            self.currentIndex = index
            Logger.imageOperations.info("Set current index to \(index) for \(firstUrl.lastPathComponent)")
        } else {
            self.currentIndex = 0
            Logger.imageOperations.info("Set current index to 0")
        }
        
        loadCurrentImage()
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
