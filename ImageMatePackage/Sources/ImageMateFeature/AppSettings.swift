//
//  AppSettings.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI

@MainActor
public class AppSettings: ObservableObject {
    @Published public var thumbnailDisplayMode: ThumbnailDisplayMode {
        didSet {
            UserDefaults.standard.set(thumbnailDisplayMode.rawValue, forKey: "thumbnailDisplayMode")
        }
    }
    
    @Published public var autoResizeWindow: Bool {
        didSet {
            UserDefaults.standard.set(autoResizeWindow, forKey: "autoResizeWindow")
        }
    }
    
    @Published public var singleWindowMode: Bool {
        didSet {
            UserDefaults.standard.set(singleWindowMode, forKey: "singleWindowMode")
        }
    }
    
    @Published public var zoomMode: ZoomMode {
        didSet {
            UserDefaults.standard.set(zoomMode.rawValue, forKey: "zoomMode")
        }
    }
    
    @Published public var apngDefaultMode: APNGDisplayMode {
        didSet {
            UserDefaults.standard.set(apngDefaultMode.rawValue, forKey: "apngDefaultMode")
        }
    }
    
    public init() {
        let savedMode = UserDefaults.standard.string(forKey: "thumbnailDisplayMode") ?? ThumbnailDisplayMode.autoHide.rawValue
        self.thumbnailDisplayMode = ThumbnailDisplayMode(rawValue: savedMode) ?? .autoHide
        
        // Default to true if never set before
        if UserDefaults.standard.object(forKey: "autoResizeWindow") == nil {
            self.autoResizeWindow = true
            UserDefaults.standard.set(true, forKey: "autoResizeWindow")
        } else {
            self.autoResizeWindow = UserDefaults.standard.bool(forKey: "autoResizeWindow")
        }
        
        if UserDefaults.standard.object(forKey: "singleWindowMode") == nil {
            self.singleWindowMode = true
            UserDefaults.standard.set(true, forKey: "singleWindowMode")
        } else {
            self.singleWindowMode = UserDefaults.standard.bool(forKey: "singleWindowMode")
        }
        
        let savedAPNG = UserDefaults.standard.string(forKey: "apngDefaultMode") ?? APNGDisplayMode.animated.rawValue
        self.apngDefaultMode = APNGDisplayMode(rawValue: savedAPNG) ?? .animated
        
        let savedZoom = UserDefaults.standard.string(forKey: "zoomMode") ?? ZoomMode.fitToWindow.rawValue
        self.zoomMode = ZoomMode(rawValue: savedZoom) ?? .fitToWindow
    }
}

public enum ThumbnailDisplayMode: String, CaseIterable, Identifiable {
    case alwaysShow = "always_show"
    case autoHide = "auto_hide"
    case alwaysHide = "always_hide"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .alwaysShow:
            return "Always Show (Resize View)"
        case .autoHide:
            return "Auto Hide"
        case .alwaysHide:
            return "Always Hide"
        }
    }
    
    public var description: String {
        switch self {
        case .alwaysShow:
            return "Thumbnails always visible, image view resized"
        case .autoHide:
            return "Thumbnails hide automatically after 2 seconds"
        case .alwaysHide:
            return "Thumbnails are never shown"
        }
    }
}

public enum ZoomMode: String, CaseIterable, Identifiable {
    case fitToWindow = "fit_to_window"
    case fillWindow = "fill_window"
    case actualSize = "actual_size"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fitToWindow: return "Fit to Window"
        case .fillWindow:  return "Fill Window"
        case .actualSize:  return "Actual Size"
        }
    }

    public var description: String {
        switch self {
        case .fitToWindow: return "Scale image to fit entirely within the window"
        case .fillWindow:  return "Scale image to fill the window (may crop edges)"
        case .actualSize:  return "Display image at 1:1 pixel size"
        }
    }
}

public enum APNGDisplayMode: String, CaseIterable, Identifiable {
    case animated = "animated"
    case frames = "frames"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .animated: return "Play Animation"
        case .frames:   return "Browse Frames"
        }
    }

    public var description: String {
        switch self {
        case .animated: return "Play APNG files as animations (default)"
        case .frames:   return "Show individual frames for browsing"
        }
    }
}
