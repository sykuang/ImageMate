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
    }
}

public enum ThumbnailDisplayMode: String, CaseIterable, Identifiable {
    case alwaysShow = "always_show"
    case autoHide = "auto_hide"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .alwaysShow:
            return "Always Show (Resize View)"
        case .autoHide:
            return "Auto Hide"
        }
    }
    
    public var description: String {
        switch self {
        case .alwaysShow:
            return "Thumbnails always visible, image view resized"
        case .autoHide:
            return "Thumbnails hide automatically after 2 seconds"
        }
    }
}
