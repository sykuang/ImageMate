//
//  Logger+ImageMate.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import Foundation
import OSLog

extension Logger {
    /// Logger for ImageMate app
    static let imageMate = Logger(subsystem: "com.imagemate.app", category: "general")
    
    /// Logger for image operations
    static let imageOperations = Logger(subsystem: "com.imagemate.app", category: "imageOperations")
    
    /// Logger for UI events
    static let ui = Logger(subsystem: "com.imagemate.app", category: "ui")
}
