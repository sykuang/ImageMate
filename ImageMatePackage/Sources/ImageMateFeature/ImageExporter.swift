//
//  ImageExporter.swift
//  ImageMate
//
//  Created on March 3, 2026.
//

import AppKit
import ImageIO
import UniformTypeIdentifiers
import OSLog

/// Supported export formats for image conversion.
public enum ExportFormat: String, CaseIterable, Identifiable {
    case heic
    case jpeg
    case png
    case tiff

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .heic: "HEIC"
        case .jpeg: "JPEG"
        case .png:  "PNG"
        case .tiff: "TIFF"
        }
    }

    public var fileExtension: String {
        switch self {
        case .heic: "heic"
        case .jpeg: "jpg"
        case .png:  "png"
        case .tiff: "tiff"
        }
    }

    public var utType: UTType {
        switch self {
        case .heic: .heic
        case .jpeg: .jpeg
        case .png:  .png
        case .tiff: .tiff
        }
    }
}

public enum ImageExportError: LocalizedError {
    case noImage
    case failedToGetCGImage
    case failedToCreateDestination
    case failedToFinalize
    case unsupportedFormat

    public var errorDescription: String? {
        switch self {
        case .noImage:                   "No image to export."
        case .failedToGetCGImage:        "Failed to create CGImage from the current image."
        case .failedToCreateDestination: "Failed to create the image file."
        case .failedToFinalize:          "Failed to write the image data."
        case .unsupportedFormat:         "The selected format is not supported on this system."
        }
    }
}

/// Handles exporting / converting images to various formats including HEIC.
public struct ImageExporter {

    /// Export `image` to `url` in the given `format`.
    ///
    /// For HEIC, `quality` controls lossy compression (0.0–1.0, default 0.85).
    /// For PNG / TIFF, `quality` is ignored.
    public static func export(
        _ image: NSImage,
        to url: URL,
        format: ExportFormat,
        quality: Double = 0.85
    ) throws {
        Logger.imageOperations.info("Exporting image as \(format.displayName) to \(url.path)")

        guard let cgImage = image.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            throw ImageExportError.failedToGetCGImage
        }

        let typeIdentifier = format.utType.identifier as CFString

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            typeIdentifier,
            1,
            nil
        ) else {
            throw ImageExportError.failedToCreateDestination
        }

        var options: [CFString: Any] = [:]

        switch format {
        case .heic, .jpeg:
            options[kCGImageDestinationLossyCompressionQuality] = quality
        case .png, .tiff:
            break // lossless – no quality knob needed
        }

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageExportError.failedToFinalize
        }

        Logger.imageOperations.info("Successfully exported image as \(format.displayName)")
    }

    /// Returns `true` if the current system supports writing HEIC images.
    public static var isHEICSupported: Bool {
        let supportedTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        return supportedTypes.contains(UTType.heic.identifier)
    }
}
