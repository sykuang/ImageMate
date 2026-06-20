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

    /// Tell SwiftUI the correct size so `.aspectRatio(contentMode: .fit)`
    /// can properly constrain this NSViewRepresentable.
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSImageView,
        context: Context
    ) -> CGSize? {
        guard let img = nsView.image else { return nil }
        let imgW = img.size.width
        let imgH = img.size.height
        guard imgW > 0, imgH > 0 else { return nil }

        let aspect = imgW / imgH

        switch (proposal.width, proposal.height) {
        case let (w?, h?):
            // Both dimensions proposed — fit within them
            if w / h > aspect {
                return CGSize(width: h * aspect, height: h)
            } else {
                return CGSize(width: w, height: w / aspect)
            }
        case let (w?, nil):
            return CGSize(width: w, height: w / aspect)
        case let (nil, h?):
            return CGSize(width: h * aspect, height: h)
        case (nil, nil):
            return CGSize(width: imgW, height: imgH)
        }
    }
}
