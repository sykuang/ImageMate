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
    }

    @Test("All cases have correct fileExtension")
    func fileExtensions() {
        #expect(ExportFormat.heic.fileExtension == "heic")
        #expect(ExportFormat.jpeg.fileExtension == "jpg")
        #expect(ExportFormat.png.fileExtension == "png")
        #expect(ExportFormat.tiff.fileExtension == "tiff")
    }

    @Test("All cases have correct utType")
    func utTypes() {
        #expect(ExportFormat.heic.utType == .heic)
        #expect(ExportFormat.jpeg.utType == .jpeg)
        #expect(ExportFormat.png.utType == .png)
        #expect(ExportFormat.tiff.utType == .tiff)
    }

    @Test("id equals rawValue")
    func idEqualsRawValue() {
        for format in ExportFormat.allCases {
            #expect(format.id == format.rawValue)
        }
    }

    @Test("CaseIterable has exactly 4 cases")
    func caseCount() {
        #expect(ExportFormat.allCases.count == 4)
    }
}
