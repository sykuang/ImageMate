//
//  ThumbnailLoader.swift
//  ImageMate
//
//  Created on March 6, 2026.
//

import AppKit
import ImageIO
import OSLog

/// Loads thumbnails with bounded concurrency and in-memory caching.
///
/// Designed for network-mounted volumes (e.g. Samba) where unbounded
/// concurrent reads cause timeouts and hangs. Uses `CGImageSource`
/// thumbnail APIs to avoid decoding full-resolution images.
public actor ThumbnailLoader {

    public static let shared = ThumbnailLoader()

    // MARK: - Configuration

    private let maxConcurrent: Int
    private let thumbnailMaxPixel: Int

    // MARK: - State

    private var activeTasks = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let cache = NSCache<NSURL, NSImage>()

    private init(maxConcurrent: Int = 4, thumbnailMaxPixel: Int = 360) {
        self.maxConcurrent = maxConcurrent
        self.thumbnailMaxPixel = thumbnailMaxPixel
        cache.countLimit = 500
    }

    // MARK: - Public API

    /// Returns a cached thumbnail or loads one from disk.
    /// Respects the concurrency limit so Samba connections aren't starved.
    public func thumbnail(for url: URL) async -> NSImage? {
        // 1. Fast path — cache hit
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // 2. Wait for a slot
        await acquireSlot()
        defer { releaseSlot() }

        // Re-check cache after acquiring slot (another task may have loaded it)
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // 3. Load on a GCD queue (not the cooperative thread pool) so
        //    blocking NAS I/O doesn't starve Swift concurrency.
        let pixel = thumbnailMaxPixel
        let image: NSImage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let result = Self.loadThumbnailFromDisk(url: url, maxPixel: pixel)
                continuation.resume(returning: result)
            }
        }

        if let image {
            cache.setObject(image, forKey: url as NSURL)
        }

        return image
    }

    /// Remove all cached thumbnails (e.g. on memory warning or directory change).
    public func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Concurrency limiter

    private func acquireSlot() async {
        if activeTasks < maxConcurrent {
            activeTasks += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        activeTasks += 1
    }

    private func releaseSlot() {
        activeTasks -= 1
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            next.resume()
        }
    }

    // MARK: - Disk I/O (off main actor)

    /// Reads the file into memory first, then creates a thumbnail via
    /// `CGImageSource`.  A single sequential read is dramatically faster
    /// over network mounts (SMB/NFS) than the many small seeks that
    /// `CGImageSourceCreateWithURL` performs.
    private static func loadThumbnailFromDisk(url: URL, maxPixel: Int) -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        // Read file data in one sequential pass (avoids multiple SMB round-trips).
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            Logger.imageOperations.error("Failed to read data for \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }

        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }

        Logger.imageOperations.debug("CGImageSource thumbnail failed for \(url.lastPathComponent), falling back to NSImage")
        return loadFallbackThumbnail(data: data, maxPixel: maxPixel)
    }

    private static func loadFallbackThumbnail(data: Data, maxPixel: Int) -> NSImage? {
        guard let image = NSImage(data: data) else { return nil }
        let targetSize = NSSize(width: maxPixel, height: maxPixel)
        return image.resized(to: targetSize)
    }
}
