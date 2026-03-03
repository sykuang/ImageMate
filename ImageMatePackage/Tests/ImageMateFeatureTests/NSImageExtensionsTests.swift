import Testing
import AppKit
@testable import ImageMateFeature

@Suite("NSImage.resized(to:) Tests")
struct NSImageExtensionsTests {

    @MainActor
    private func makeImage(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }

    @MainActor @Test("Resizing 200x100 to 100x100 returns correct size")
    func resizeDown() {
        let original = makeImage(width: 200, height: 100)
        let resized = original.resized(to: CGSize(width: 100, height: 100))
        #expect(resized.size.width == 100)
        #expect(resized.size.height == 100)
    }

    @MainActor @Test("Resizing 50x50 to 100x100 returns correct size")
    func resizeUp() {
        let original = makeImage(width: 50, height: 50)
        let resized = original.resized(to: CGSize(width: 100, height: 100))
        #expect(resized.size.width == 100)
        #expect(resized.size.height == 100)
    }

    @MainActor @Test("Original image is unchanged after resize")
    func originalUnchanged() {
        let original = makeImage(width: 200, height: 100)
        let originalSize = original.size
        _ = original.resized(to: CGSize(width: 50, height: 50))
        #expect(original.size.width == originalSize.width)
        #expect(original.size.height == originalSize.height)
    }
}
