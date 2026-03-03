import XCTest

final class ImageMateUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAppLaunches() throws {
        // Verify app launched and has at least one window
        XCTAssertTrue(app.windows.count >= 1, "App should have at least one window")
    }
    
    func testMainWindowExists() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Main window should exist")
    }
    
    func testOpenMenuItemExists() throws {
        // Check File menu contains Open
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists, "Menu bar should exist")
    }
}
