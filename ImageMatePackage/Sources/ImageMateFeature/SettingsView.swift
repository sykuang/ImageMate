//
//  SettingsView.swift
//  ImageMate
//
//  Created on October 20, 2025.
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    
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
            }
            .padding()
            
            Spacer()
        }
        .frame(width: 450, height: 400)
        .padding()
    }
}
