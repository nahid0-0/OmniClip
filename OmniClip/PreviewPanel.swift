import SwiftUI
import AppKit

// Virtualized text view - only renders visible lines, handles 100K+ chars smoothly
private struct ScrollableTextView: NSViewRepresentable {
    let text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure text view
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let textView = scrollView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
                textView.scrollToBeginningOfDocument(nil)
            }
        }
    }
}

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
            
            // Content area - uses virtualized NSTextView for text, SwiftUI for images
            contentArea
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
                        Text("\(textClip.text.utf16.count) characters")
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
    private var contentArea: some View {
        switch clip {
        case .text(let textClip):
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Clip")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                ScrollableTextView(text: textClip.text)
                    .cornerRadius(6)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            
        case .image(let imageClip):
            ScrollView {
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
                .padding(16)
            }
            .scrollIndicators(.never)
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
