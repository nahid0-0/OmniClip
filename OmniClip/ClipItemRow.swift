import SwiftUI
import AppKit

struct ClipItemRow: View, Equatable {
    let clip: ClipType
    let isSelected: Bool
    let showTimestamp: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    
    @State private var isHovering = false
    
    static func == (lhs: ClipItemRow, rhs: ClipItemRow) -> Bool {
        lhs.clip.id == rhs.clip.id &&
        lhs.isSelected == rhs.isSelected &&
        lhs.showTimestamp == rhs.showTimestamp &&
        lhs.clip.isPinned == rhs.clip.isPinned
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                // Content preview
                contentPreview
                
                Spacer()
                
                // Copy button (appears on hover)
                if isHovering {
                    Button(action: {
                        onCopy()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")
                }
                
                // Pin indicator
                if clip.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        switch clip {
        case .text(let textClip):
            VStack(alignment: .leading, spacing: 4) {
                Text(String(textClip.text.prefix(200)))
                    .lineLimit(2)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if showTimestamp {
                    Text(dateFormatter.string(from: textClip.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .image(let imageClip):
            HStack(spacing: 8) {
                // Thumbnail
                if let thumbnail = imageClip.thumbnail() {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.caption)
                        Text("Image")
                            .font(.system(size: 13))
                    }
                    
                    Text("\(imageClip.width) × \(imageClip.height)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if showTimestamp {
                        Text(dateFormatter.string(from: imageClip.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
