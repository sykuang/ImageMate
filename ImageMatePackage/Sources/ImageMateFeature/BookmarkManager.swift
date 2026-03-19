//
//  BookmarkManager.swift
//  ImageMate
//
//  Persists security-scoped bookmarks so the user only needs to grant
//  folder access once per directory.
//

import Foundation
import OSLog

@MainActor
public final class BookmarkManager {

    public static let shared = BookmarkManager()

    private let bookmarkKey = "SecurityScopedBookmarks"
    private let defaults = UserDefaults.standard
    private var activeURLs: [String: URL] = [:]

    private init() {}

    // MARK: - Save

    /// Create and persist a security-scoped bookmark for `url`.
    public func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            var bookmarks = defaults.dictionary(forKey: bookmarkKey) as? [String: Data] ?? [:]
            bookmarks[url.path] = data
            defaults.set(bookmarks, forKey: bookmarkKey)
            Logger.imageOperations.info("Saved bookmark for: \(url.path)")
        } catch {
            Logger.imageOperations.error("Failed to create bookmark for \(url.path): \(error.localizedDescription)")
        }
    }

    // MARK: - Restore

    /// Try to restore a previously saved bookmark for `directoryPath`.
    /// Returns the resolved URL with active security scope, or `nil`.
    public func restoreBookmark(for directoryPath: String) -> URL? {
        guard let bookmarks = defaults.dictionary(forKey: bookmarkKey) as? [String: Data],
              let data = bookmarks[directoryPath] else {
            return nil
        }

        // Already active in this session – return cached URL.
        if let cached = activeURLs[directoryPath] {
            return cached
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                Logger.imageOperations.info("Bookmark stale for \(directoryPath), re-saving")
                saveBookmark(for: url)
            }

            guard url.startAccessingSecurityScopedResource() else {
                Logger.imageOperations.error("startAccessingSecurityScopedResource failed for \(directoryPath)")
                return nil
            }

            activeURLs[directoryPath] = url
            Logger.imageOperations.info("Restored bookmark for: \(directoryPath)")
            return url
        } catch {
            Logger.imageOperations.error("Failed to resolve bookmark for \(directoryPath): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Cleanup

    /// Stop accessing all active security-scoped resources.
    public func stopAccessingAll() {
        for (_, url) in activeURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeURLs.removeAll()
    }
}
