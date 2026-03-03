import Testing
import AppKit
@testable import ImageMateFeature

@Suite("ImageExporter Tests")
struct ImageExporterTests {

    private func makeTestImage(width: Int, height: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }

    private func tempURL(ext: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("isHEICSupported returns a Bool without crashing")
    func heicSupportedCheck() {
        let result = ImageExporter.isHEICSupported
        // Just verify it returns a Bool value (true or false)
        #expect(result == true || result == false)
    }

    @Test("Export PNG creates file")
    func exportPNG() throws {
        let image = makeTestImage(width: 100, height: 100)
        let url = tempURL(ext: "png")
        defer { cleanup(url) }

        try ImageExporter.export(image, to: url, format: .png)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Export JPEG creates file")
    func exportJPEG() throws {
        let image = makeTestImage(width: 100, height: 100)
        let url = tempURL(ext: "jpg")
        defer { cleanup(url) }

        try ImageExporter.export(image, to: url, format: .jpeg)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Export TIFF creates file")
    func exportTIFF() throws {
        let image = makeTestImage(width: 100, height: 100)
        let url = tempURL(ext: "tiff")
        defer { cleanup(url) }

        try ImageExporter.export(image, to: url, format: .tiff)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Export HEIC creates file if supported")
    func exportHEIC() throws {
        guard ImageExporter.isHEICSupported else {
            return // Skip on systems without HEIC support
        }
        let image = makeTestImage(width: 100, height: 100)
        let url = tempURL(ext: "heic")
        defer { cleanup(url) }

        try ImageExporter.export(image, to: url, format: .heic)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Export with 1x1 image works")
    func exportSmallImage() throws {
        let image = makeTestImage(width: 1, height: 1)
        let url = tempURL(ext: "png")
        defer { cleanup(url) }

        try ImageExporter.export(image, to: url, format: .png)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }
}
