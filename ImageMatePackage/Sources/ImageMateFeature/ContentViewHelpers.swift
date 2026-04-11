//
//  ContentViewHelpers.swift
//  ImageMate
//
//  Created on April 11, 2026.
//

import SwiftUI

// MARK: - Thumbnail View

struct ThumbnailView: View {
    let url: URL
    let isSelected: Bool
    @State private var thumbnail: NSImage?
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .shadow(radius: 4)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(ProgressView().controlSize(.small))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        isLoading = true
        loadTask = Task {
            let image = await ThumbnailLoader.shared.thumbnail(for: url)
            guard !Task.isCancelled else { return }
            thumbnail = image
            isLoading = false
        }
    }
}

// MARK: - Image Info View

struct ImageInfoView: View {
    let image: NSImage
    let fileName: String
    let fileUrl: URL?
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Image Information")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Divider()

            InfoRow(label: "Name", value: fileName)
            InfoRow(label: "Size", value: "\(Int(image.size.width)) × \(Int(image.size.height))")

            if let fileUrl = fileUrl {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileUrl.path),
                   let fileSize = attributes[.size] as? Int64 {
                    InfoRow(label: "File Size", value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                }

                InfoRow(label: "Path", value: fileUrl.path)
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
