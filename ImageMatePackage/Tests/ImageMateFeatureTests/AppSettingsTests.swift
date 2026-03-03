import Foundation
import Testing
@testable import ImageMateFeature

@Suite("AppSettings Tests")
struct AppSettingsTests {

    private static let thumbnailKey = "thumbnailDisplayMode"
    private static let autoResizeKey = "autoResizeWindow"

    private func cleanDefaults() {
        UserDefaults.standard.removeObject(forKey: AppSettingsTests.thumbnailKey)
        UserDefaults.standard.removeObject(forKey: AppSettingsTests.autoResizeKey)
    }

    @MainActor @Test("Default thumbnailDisplayMode is autoHide")
    func defaultThumbnailMode() {
        cleanDefaults()
        let settings = AppSettings()
        #expect(settings.thumbnailDisplayMode == .autoHide)
    }

    @MainActor @Test("Default autoResizeWindow is true when UserDefaults has no prior value")
    func defaultAutoResize() {
        cleanDefaults()
        let settings = AppSettings()
        #expect(settings.autoResizeWindow == true)
    }

    @MainActor @Test("Setting thumbnailDisplayMode persists to UserDefaults")
    func persistThumbnailMode() {
        cleanDefaults()
        let settings = AppSettings()
        settings.thumbnailDisplayMode = .alwaysShow
        let stored = UserDefaults.standard.string(forKey: AppSettingsTests.thumbnailKey)
        #expect(stored == ThumbnailDisplayMode.alwaysShow.rawValue)
    }

    @MainActor @Test("Setting autoResizeWindow persists to UserDefaults")
    func persistAutoResize() {
        cleanDefaults()
        let settings = AppSettings()
        settings.autoResizeWindow = false
        let stored = UserDefaults.standard.bool(forKey: AppSettingsTests.autoResizeKey)
        #expect(stored == false)
    }
}
