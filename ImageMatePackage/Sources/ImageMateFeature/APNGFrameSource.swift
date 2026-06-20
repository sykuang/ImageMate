//
//  APNGFrameSource.swift
//  ImageMate
//
//  Created on April 11, 2026.
//

import AppKit
import ImageIO
import OSLog

/// Provides lazy, cached access to individual frames of an APNG file.
///
/// Keeps the compressed `CGImageSource` in memory (small) and extracts
/// frames on-demand via `CGImageSourceCreateImageAtIndex`.  An `NSCache`
/// holds recently viewed frames and auto-evicts under memory pressure.
public final class APNGFrameSource: @unchecked Sendable {

    let frameCount: Int
    let sourceURL: URL

    private let imageSource: CGImageSource
    private let data: Data
    private let frameCache = NSCache<NSNumber, NSImage>()
    private let thumbCache = NSCache<NSNumber, NSImage>()

    init?(url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        // Only treat multi-frame PNGs as APNG (not GIF or other multi-frame formats)
        guard let utType = CGImageSourceGetType(source) as String?,
              utType == "public.png" else { return nil }

        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil }

        self.data = data
        self.imageSource = source
        self.frameCount = count
        self.sourceURL = url

        frameCache.countLimit = 30
        thumbCache.countLimit = 200
    }

    /// Returns the full-resolution frame at `index`, using a cache.
    func frame(at index: Int) -> NSImage? {
        guard index >= 0, index < frameCount else { return nil }

        let key = NSNumber(value: index)
        if let cached = frameCache.object(forKey: key) {
            return cached
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            Logger.imageOperations.error("Failed to extract APNG frame \(index) from \(self.sourceURL.lastPathComponent)")
            return nil
        }

        let image = NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
        frameCache.setObject(image, forKey: key)
        return image
    }

    /// Returns a downscaled thumbnail for the frame at `index`.
    func thumbnail(at index: Int, maxPixel: Int = 360) -> NSImage? {
        guard index >= 0, index < frameCount else { return nil }

        let key = NSNumber(value: index)
        if let cached = thumbCache.object(forKey: key) {
            return cached
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource, index, options as CFDictionary
        ) else {
            return frame(at: index)
        }

        let image = NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
        thumbCache.setObject(image, forKey: key)
        return image
    }

    /// Quick check: is the file at `url` a multi-frame PNG (APNG)?
    static func isAPNG(url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let utType = CGImageSourceGetType(source) as String?,
              utType == "public.png" else { return false }
        return CGImageSourceGetCount(source) > 1
    }
}
