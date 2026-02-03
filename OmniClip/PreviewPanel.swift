import SwiftUI
import AppKit

struct PreviewPanel: View {
    let clip: ClipType
    let clipboardManager: ClipboardManager
    let onClose: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with actions
            HStack {
                Text(clip.isPinned ? "Pinned" : "Unpinned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    clipboardManager.togglePin(for: clip.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: clip.isPinned ? "pin.slash" : "pin")
                        Text(clip.isPinned ? "Unpin" : "Pin")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(4)
                
                Button(action: {
                    clipboardManager.delete(clipID: clip.id)
                    onClose()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    contentView
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            // Footer with copy button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateFormatter.string(from: clip.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if case .text(let textClip) = clip {
                        Text("\(textClip.text.count) characters")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else if case .image(let imageClip) = clip {
                        Text("\(imageClip.width) × \(imageClip.height) • \(formatBytes(imageClip.imageData.count))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    clipboardManager.copyToClipboard(clip)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                            .font(.body.weight(.medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch clip {
        case .text(let textClip):
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Clip")
                    .font(.headline)
                
                Text(textClip.text)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
            }
            
        case .image(let imageClip):
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Clip")
                    .font(.headline)
                
                if let fullImage = imageClip.fullImage() {
                    Image(nsImage: fullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    Text("Unable to display image")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
