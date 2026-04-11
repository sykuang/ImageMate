import Testing
import UniformTypeIdentifiers
@testable import ImageMateFeature

@Suite("ExportFormat Tests")
struct ExportFormatTests {

    @Test("All cases have correct displayName")
    func displayNames() {
        #expect(ExportFormat.heic.displayName == "HEIC")
        #expect(ExportFormat.jpeg.displayName == "JPEG")
        #expect(ExportFormat.png.displayName == "PNG")
        #expect(ExportFormat.tiff.displayName == "TIFF")
        #expect(ExportFormat.gif.displayName == "GIF")
        #expect(ExportFormat.webp.displayName == "WebP")
        #expect(ExportFormat.bmp.displayName == "BMP")
    }

    @Test("All cases have correct fileExtension")
    func fileExtensions() {
        #expect(ExportFormat.heic.fileExtension == "heic")
        #expect(ExportFormat.jpeg.fileExtension == "jpg")
        #expect(ExportFormat.png.fileExtension == "png")
        #expect(ExportFormat.tiff.fileExtension == "tiff")
        #expect(ExportFormat.gif.fileExtension == "gif")
        #expect(ExportFormat.webp.fileExtension == "webp")
        #expect(ExportFormat.bmp.fileExtension == "bmp")
    }

    @Test("All cases have correct utType")
    func utTypes() {
        #expect(ExportFormat.heic.utType == .heic)
        #expect(ExportFormat.jpeg.utType == .jpeg)
        #expect(ExportFormat.png.utType == .png)
        #expect(ExportFormat.tiff.utType == .tiff)
        #expect(ExportFormat.gif.utType == .gif)
        #expect(ExportFormat.webp.utType == .webP)
        #expect(ExportFormat.bmp.utType == .bmp)
    }

    @Test("id equals rawValue")
    func idEqualsRawValue() {
        for format in ExportFormat.allCases {
            #expect(format.id == format.rawValue)
        }
    }

    @Test("CaseIterable has exactly 7 cases")
    func caseCount() {
        #expect(ExportFormat.allCases.count == 7)
    }
}
