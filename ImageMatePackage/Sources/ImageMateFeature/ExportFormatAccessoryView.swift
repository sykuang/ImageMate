//
//  ExportFormatAccessoryView.swift
//  ImageMate
//
//  Created on March 3, 2026.
//

import SwiftUI

/// Accessory view embedded in NSSavePanel for choosing the export format.
struct ExportFormatAccessoryView: View {
    @State private var selectedFormat: ExportFormat = .heic
    var onFormatChanged: (ExportFormat) -> Void

    var body: some View {
        HStack {
            Text("Format:")
                .font(.body)
            Picker("", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedFormat) {
                onFormatChanged(selectedFormat)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
