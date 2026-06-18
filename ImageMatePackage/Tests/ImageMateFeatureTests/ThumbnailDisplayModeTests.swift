import Testing
@testable import ImageMateFeature

@Suite("ThumbnailDisplayMode Tests")
struct ThumbnailDisplayModeTests {

    @Test("rawValue correctness")
    func rawValues() {
        #expect(ThumbnailDisplayMode.alwaysShow.rawValue == "always_show")
        #expect(ThumbnailDisplayMode.autoHide.rawValue == "auto_hide")
        #expect(ThumbnailDisplayMode.alwaysHide.rawValue == "always_hide")
    }

    @Test("displayName non-empty for all cases")
    func displayNames() {
        for mode in ThumbnailDisplayMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }

    @Test("description non-empty for all cases")
    func descriptions() {
        for mode in ThumbnailDisplayMode.allCases {
            #expect(!mode.description.isEmpty)
        }
    }

    @Test("CaseIterable has exactly 3 cases")
    func caseCount() {
        #expect(ThumbnailDisplayMode.allCases.count == 3)
    }

    @Test("id equals rawValue")
    func idEqualsRawValue() {
        for mode in ThumbnailDisplayMode.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }
}
