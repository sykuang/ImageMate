import Testing
@testable import ImageMateFeature

@Suite("ImageExportError Tests")
struct ImageExportErrorTests {

    @Test("All cases have non-nil errorDescription")
    func errorDescriptionsNonNil() {
        let cases: [ImageExportError] = [
            .noImage,
            .failedToGetCGImage,
            .failedToCreateDestination,
            .failedToFinalize,
            .unsupportedFormat,
        ]
        for error in cases {
            #expect(error.errorDescription != nil)
        }
    }

    @Test("noImage description contains expected keyword")
    func noImageDescription() {
        #expect(ImageExportError.noImage.errorDescription?.contains("No image") == true)
    }

    @Test("failedToGetCGImage description contains expected keyword")
    func failedToGetCGImageDescription() {
        #expect(ImageExportError.failedToGetCGImage.errorDescription?.contains("CGImage") == true)
    }

    @Test("failedToCreateDestination description contains expected keyword")
    func failedToCreateDestinationDescription() {
        #expect(ImageExportError.failedToCreateDestination.errorDescription?.contains("create") == true)
    }

    @Test("failedToFinalize description contains expected keyword")
    func failedToFinalizeDescription() {
        #expect(ImageExportError.failedToFinalize.errorDescription?.contains("write") == true)
    }

    @Test("unsupportedFormat description contains expected keyword")
    func unsupportedFormatDescription() {
        #expect(ImageExportError.unsupportedFormat.errorDescription?.contains("not supported") == true)
    }
}
