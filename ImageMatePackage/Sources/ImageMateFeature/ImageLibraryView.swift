//
//  ImageLibraryView.swift
//  ImageMate
//
//  Created on October 21, 2025.
//

import SwiftUI
import OSLog

public struct ImageLibraryView: View {
    let imageUrls: [URL]
    let onSelect: (Int) -> Void
    let onCancel: () -> Void
    
    @State private var hoveredIndex: Int?
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    public init(imageUrls: [URL], onSelect: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.imageUrls = imageUrls
        self.onSelect = onSelect
        self.onCancel = onCancel
    }
    
    private var filteredUrls: [URL] {
        if searchText.isEmpty {
            return imageUrls
        }
        return imageUrls.filter { url in
            url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select an Image")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(filteredUrls.count) images found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search images...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Image grid
            ScrollView {
                if filteredUrls.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No images found")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(filteredUrls.enumerated()), id: \.offset) { index, url in
                            ImageThumbnailCell(
                                url: url,
                                isHovered: hoveredIndex == index,
                                onTap: {
                                    if let originalIndex = imageUrls.firstIndex(of: url) {
                                        onSelect(originalIndex)
                                    }
                                }
                            )
                            .onHover { isHovered in
                                hoveredIndex = isHovered ? index : nil
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct ImageThumbnailCell: View {
    let url: URL
    let isHovered: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                        .clipped()
                        .cornerRadius(8)
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // Hover overlay
                if isHovered {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 3)
                        )
                }
            }
            
            Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 180)
                .foregroundColor(isHovered ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task.detached(priority: .userInitiated) {
            guard let image = NSImage(contentsOf: url) else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            // Create thumbnail
            let thumbSize = NSSize(width: 180, height: 180)
            let thumb = image.resized(to: thumbSize)
            
            await MainActor.run {
                self.thumbnail = thumb
                self.isLoading = false
            }
        }
    }
}
