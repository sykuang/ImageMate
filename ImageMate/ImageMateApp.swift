//
//  ImageMateApp.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI
import ImageMateFeature
import OSLog
import AppKit

private let logger = Logger(subsystem: "com.primattek.ImageMate", category: "App")

// Suppress automatic new-window creation from file-open events.
// macOS + CFBundleDocumentTypes + WindowGroup = new window per file open.
// File opens are routed exclusively through AppDelegate.application(_:open:).
private class ImageMateDocumentController: NSDocumentController {
    override func openDocument(
        withContentsOf url: URL,
        display displayDocument: Bool,
        completionHandler: @escaping (NSDocument?, Bool, (any Error)?) -> Void
    ) {
        completionHandler(nil, false, nil)
    }

    override func reopenDocument(
        for urlOrNil: URL?,
        withContentsOf contentsURL: URL,
        display displayDocument: Bool,
        completionHandler: @escaping (NSDocument?, Bool, (any Error)?) -> Void
    ) {
        completionHandler(nil, false, nil)
    }
}

@main
struct ImageMateApp: App {
    @StateObject private var settings = AppSettings()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        logger.info("🚀 ImageMate app initializing")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Images or Folder...") {
                    openImage()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Export As...") {
                    exportImage()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    private func openImage() {
        logger.info("📂 Open image menu triggered")
        // Trigger the open image action in the ContentView
        // We need to post a notification that ContentView can listen to
        NotificationCenter.default.post(name: NSNotification.Name("OpenImageFromMenu"), object: nil)
    }
    
    private func exportImage() {
        logger.info("📤 Export image menu triggered")
        NotificationCenter.default.post(name: NSNotification.Name("ExportImageFromMenu"), object: nil)
    }
    
    private func openSettings() {
        // Check if settings window already exists
        let settingsWindow = NSApplication.shared.windows.first { window in
            window.identifier?.rawValue == "SettingsWindow"
        }
        
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new settings window
            let settingsView = SettingsView(settings: settings)
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.identifier = NSUserInterfaceItemIdentifier("SettingsWindow")
            window.title = "Settings"
            window.contentViewController = hostingController
            window.center()
            window.makeKeyAndOrderFront(nil)
            window.isReleasedWhenClosed = false
        }
    }
}

// AppDelegate to handle file/folder opening from Finder
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Must register before the default NSDocumentController is created
        _ = ImageMateDocumentController()
        logger.info("📋 Registered custom document controller to suppress auto window creation")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("✅ AppDelegate: Application did finish launching")
        logger.info("📋 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        logger.info("📋 Registered document types: \(String(describing: Bundle.main.infoDictionary?["CFBundleDocumentTypes"]))")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        logger.info("🚪 Last window closed - quitting app")
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag && UserDefaults.standard.bool(forKey: "singleWindowMode") {
            focusMainWindow(sender)
            return false
        }
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        logger.info("🎯 AppDelegate: application:open: called with \(urls.count) URLs")
        for url in urls {
            logger.info("   📄 URL: \(url.path)")
        }
        
        guard let url = urls.first else {
            logger.warning("⚠️ No URLs to open")
            return
        }
        
        // Store for cold-start: ContentView may not have registered its
        // observer yet, so the notification would be lost.
        OpenWithCoordinator.shared.pendingURL = url
        
        closeDuplicateWindows(application) {
            logger.info("📨 Posting OpenURLFromFinder notification for: \(url.path)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenURLFromFinder"),
                    object: nil,
                    userInfo: ["url": url]
                )
            }
        }
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        logger.info("🎯 AppDelegate: openFile: called with filename: \(filename)")
        let url = URL(fileURLWithPath: filename)
        
        OpenWithCoordinator.shared.pendingURL = url
        
        closeDuplicateWindows(sender) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenURLFromFinder"),
                    object: nil,
                    userInfo: ["url": url]
                )
            }
        }
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        logger.info("🎯 AppDelegate: openFiles: called with \(filenames.count) files")
        for filename in filenames {
            logger.info("   📄 File: \(filename)")
        }
        
        guard let filename = filenames.first else {
            logger.warning("⚠️ No files to open")
            return
        }
        
        let url = URL(fileURLWithPath: filename)
        OpenWithCoordinator.shared.pendingURL = url
        
        closeDuplicateWindows(sender) {
            logger.info("📨 Posting OpenURLFromFinder notification for: \(url.path)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenURLFromFinder"),
                    object: nil,
                    userInfo: ["url": url]
                )
            }
        }
    }
    
    // MARK: - Single Window Mode Helpers
    
    private func focusMainWindow(_ application: NSApplication) {
        let mainWindow = application.windows.first {
            $0.identifier?.rawValue != "SettingsWindow" && $0.isVisible
        }
        mainWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func closeDuplicateWindows(_ application: NSApplication, completion: @escaping () -> Void) {
        guard UserDefaults.standard.bool(forKey: "singleWindowMode") else {
            completion()
            return
        }
        
        DispatchQueue.main.async {
            let contentWindows = application.windows.filter { window in
                window.isVisible
                    && window.identifier?.rawValue != "SettingsWindow"
                    && !(window is NSPanel)
            }
            if let first = contentWindows.first {
                first.makeKeyAndOrderFront(nil)
                for window in contentWindows.dropFirst() {
                    logger.info("🔒 Single window mode: closing duplicate window")
                    window.close()
                }
            }
            completion()
        }
    }
}
