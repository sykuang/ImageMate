//
//  SettingsView.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var isDefaultViewer = false
    @State private var showSetDefaultAlert = false
    
    private static let imageTypes: [UTType] = [
        .jpeg, .png, .gif, .bmp, .tiff, .heic, .heif,
        .svg, .rawImage, .image,
    ]
    
    public init(settings: AppSettings) {
        self.settings = settings
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Thumbnail Display")
                    .font(.headline)
                
                ForEach(ThumbnailDisplayMode.allCases) { mode in
                    HStack {
                        Button(action: {
                            settings.thumbnailDisplayMode = mode
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: settings.thumbnailDisplayMode == mode ? "circle.inset.filled" : "circle")
                                    .foregroundColor(settings.thumbnailDisplayMode == mode ? .blue : .secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(settings.thumbnailDisplayMode == mode ? Color.blue.opacity(0.1) : Color.clear)
                    )
                }
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Window Behavior")
                    .font(.headline)
                
                Toggle(isOn: $settings.autoResizeWindow) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Resize Window")
                            .font(.body)
                        
                        Text("Automatically resize window to fit image size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                
                Toggle(isOn: $settings.singleWindowMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Single Window Mode")
                            .font(.body)
                        
                        Text("Reuse existing window when opening new images instead of creating a new window")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Default Application")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Image Viewer")
                            .font(.body)
                        
                        Text(isDefaultViewer
                             ? "ImageMate is the default viewer for images"
                             : "Set ImageMate as the default app for opening images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isDefaultViewer {
                        Label("Default", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.body)
                    } else {
                        Button("Set as Default") {
                            setAsDefaultImageViewer()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(width: 450, height: 520)
        .padding()
        .onAppear {
            isDefaultViewer = checkIsDefaultViewer()
        }
        .alert("Default Application Updated", isPresented: $showSetDefaultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ImageMate has been set as the default application for common image formats.")
        }
    }
    
    // MARK: - Default App Helpers
    
    private func checkIsDefaultViewer() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        // Check against JPEG as a representative type
        guard let handler = LSCopyDefaultRoleHandlerForContentType(
            UTType.jpeg.identifier as CFString,
            .viewer
        )?.takeRetainedValue() as String? else {
            return false
        }
        return handler.caseInsensitiveCompare(bundleID) == .orderedSame
    }
    
    private func setAsDefaultImageViewer() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        
        for type in Self.imageTypes {
            LSSetDefaultRoleHandlerForContentType(
                type.identifier as CFString,
                .viewer,
                bundleID as CFString
            )
        }
        
        Logger.imageOperations.info("Set ImageMate as default viewer for image types")
        isDefaultViewer = true
        showSetDefaultAlert = true
    }
}
