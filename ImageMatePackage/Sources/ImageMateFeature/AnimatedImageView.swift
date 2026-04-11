//
//  AnimatedImageView.swift
//  ImageMate
//
//  Created on April 11, 2026.
//

import SwiftUI
import AppKit

/// An `NSViewRepresentable` wrapping `NSImageView` so that animated formats
/// (APNG, GIF) play back correctly.  SwiftUI's `Image(nsImage:)` only
/// renders a single frame; `NSImageView` with `animates = true` handles
/// both static and animated images natively.
struct AnimatedImageView: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = true
        view.isEditable = false
        view.image = image
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if nsView.image !== image {
            nsView.image = image
        }
    }
}
