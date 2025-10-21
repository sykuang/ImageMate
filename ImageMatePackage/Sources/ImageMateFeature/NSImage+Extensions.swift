//
//  NSImage+Extensions.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import AppKit

extension NSImage {
    /// Resize image to fit within the specified size while maintaining aspect ratio
    func resized(to targetSize: CGSize) -> NSImage {
        let frame = NSRect(origin: .zero, size: targetSize)
        
        guard let representation = bestRepresentation(for: frame, context: nil, hints: nil) else {
            return self
        }
        
        let image = NSImage(size: targetSize)
        image.lockFocus()
        
        if representation.draw(in: frame) {
            image.unlockFocus()
            return image
        }
        
        image.unlockFocus()
        return self
    }
}
