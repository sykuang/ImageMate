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
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists, "Menu bar should exist")
        
        let fileMenuItem = menuBar.menuBarItems["File"]
        XCTAssertTrue(fileMenuItem.exists, "File menu should exist in the menu bar")
        
        fileMenuItem.click()
        
        let openMenuItem = fileMenuItem.menus.menuItems["Open Images or Folder..."]
        XCTAssertTrue(openMenuItem.exists, "File menu should contain 'Open Images or Folder...' item")
    }
}
