//
//  ImageMateApp.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI
import ImageMateFeature
import OSLog

private let logger = Logger(subsystem: "com.primattek.ImageMate", category: "App")

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
                .onOpenURL { url in
                    logger.info("📥 onOpenURL called with: \(url.path)")
                    handleOpenURL(url)
                }
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
    
    private func handleOpenURL(_ url: URL) {
        logger.info("🔗 handleOpenURL called with: \(url.path)")
        // Post notification with the URL to open
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenURLFromFinder"),
            object: nil,
            userInfo: ["url": url]
        )
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("✅ AppDelegate: Application did finish launching")
        logger.info("📋 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        logger.info("📋 Registered document types: \(String(describing: Bundle.main.infoDictionary?["CFBundleDocumentTypes"]))")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        logger.info("🚪 Last window closed - quitting app")
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
        
        logger.info("📨 Posting OpenURLFromFinder notification for: \(url.path)")
        // Post notification with the URL to open
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenURLFromFinder"),
            object: nil,
            userInfo: ["url": url]
        )
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        logger.info("🎯 AppDelegate: openFile: called with filename: \(filename)")
        let url = URL(fileURLWithPath: filename)
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenURLFromFinder"),
            object: nil,
            userInfo: ["url": url]
        )
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
        logger.info("📨 Posting OpenURLFromFinder notification for: \(url.path)")
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenURLFromFinder"),
            object: nil,
            userInfo: ["url": url]
        )
    }
}
