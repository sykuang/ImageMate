import Testing
import AppKit
@testable import ImageMateFeature

@Suite("ImageViewModel Tests")
struct ImageViewModelTests {

    @MainActor @Test("Initial state: currentImage is nil")
    func initialCurrentImage() {
        let vm = ImageViewModel()
        #expect(vm.currentImage == nil)
    }

    @MainActor @Test("Initial state: currentIndex is 0")
    func initialCurrentIndex() {
        let vm = ImageViewModel()
        #expect(vm.currentIndex == 0)
    }

    @MainActor @Test("Initial state: imageUrls is empty")
    func initialImageUrls() {
        let vm = ImageViewModel()
        #expect(vm.imageUrls.isEmpty)
    }

    @MainActor @Test("currentFileName returns nil when no images loaded")
    func currentFileNameNil() {
        let vm = ImageViewModel()
        #expect(vm.currentFileName == nil)
    }

    @MainActor @Test("currentFileUrl returns nil when no images loaded")
    func currentFileUrlNil() {
        let vm = ImageViewModel()
        #expect(vm.currentFileUrl == nil)
    }

    @MainActor @Test("nextImage with empty imageUrls does not crash")
    func nextImageEmpty() {
        let vm = ImageViewModel()
        vm.nextImage()
        #expect(vm.currentIndex == 0)
        #expect(vm.imageUrls.isEmpty)
    }

    @MainActor @Test("previousImage with empty imageUrls does not crash")
    func previousImageEmpty() {
        let vm = ImageViewModel()
        vm.previousImage()
        #expect(vm.currentIndex == 0)
        #expect(vm.imageUrls.isEmpty)
    }

    @MainActor @Test("selectImage with out-of-bounds index does not crash")
    func selectImageOutOfBounds() {
        let vm = ImageViewModel()
        vm.selectImage(at: 5)
        #expect(vm.currentIndex == 0)
        vm.selectImage(at: -1)
        #expect(vm.currentIndex == 0)
    }
}
