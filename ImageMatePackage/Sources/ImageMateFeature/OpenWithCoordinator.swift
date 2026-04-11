//
//  OpenWithCoordinator.swift
//  ImageMateFeature
//
//  Bridges the gap between AppDelegate (app target) and ContentView (package).
//  On cold start, application(_:open:) fires before ContentView registers its
//  NotificationCenter observer, so the notification is lost. The coordinator
//  stores the URL so ContentView can pick it up in onAppear.
//

import Foundation

@MainActor
public final class OpenWithCoordinator {
    public static let shared = OpenWithCoordinator()
    public var pendingURL: URL?
    private init() {}
}
