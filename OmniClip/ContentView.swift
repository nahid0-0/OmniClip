import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var appSettings: AppSettings
    @State private var selectedClipID: UUID?
    @State private var searchText = ""
    
    var selectedClip: ClipType? {
        guard let id = selectedClipID else { return nil }
        return clipboardManager.clips.first { $0.id == id }
    }
    
    var filteredClips: [ClipType] {
        let clips = clipboardManager.sortedClips
        
        if searchText.isEmpty {
            return clips
        }
        
        return clips.filter { clip in
            switch clip {
            case .text(let textClip):
                return textClip.text.localizedCaseInsensitiveContains(searchText)
            case .image:
                return false // Images don't have searchable text
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side: List of clips
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search clips...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Clips list
                if filteredClips.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clipboard")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "No clips yet" : "No matching clips")
                            .foregroundColor(.secondary)
                        if searchText.isEmpty {
                            Text("Copy something to get started")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredClips) { clip in
                                EquatableView(content: ClipItemRow(
                                    clip: clip,
                                    isSelected: selectedClipID == clip.id,
                                    showTimestamp: appSettings.showTimestamps,
                                    onSelect: {
                                        selectedClipID = clip.id
                                        if appSettings.copyOnClick {
                                            clipboardManager.copyToClipboard(clip)
                                        }
                                    },
                                    onCopy: {
                                        clipboardManager.copyToClipboard(clip)
                                    }
                                ))
                                Divider()
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
                
                Divider()
                
                // Bottom toolbar
                HStack(spacing: 12) {
                    Text("\(filteredClips.count) clips")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Clear Unpinned") {
                            clipboardManager.clearUnpinned()
                            selectedClipID = nil
                        }
                        Button("Clear All") {
                            clipboardManager.clearAll()
                            selectedClipID = nil
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24, height: 24)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(width: 320)
            
            Divider()
            
            // Right side: Preview panel
            if let clip = selectedClip {
                PreviewPanel(
                    clip: clip,
                    clipboardManager: clipboardManager,
                    onClose: { self.selectedClipID = nil }
                )
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: appSettings.copyOnClick ? "hand.tap" : "arrow.left")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(appSettings.copyOnClick ? "Click any clip to copy" : "Select a clip to preview")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .frame(width: 700, height: 500)
    }
}
