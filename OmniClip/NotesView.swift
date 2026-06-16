import SwiftUI
import AppKit

// MARK: - Notes Root View (in-app page)

struct NotesView: View {
    @ObservedObject var noteManager: NoteManager
    @ObservedObject var appSettings: AppSettings

    @State private var selectedNoteID: UUID?
    @State private var filterType: String = "All"   // All / Text / Form
    @State private var leftPanelWidth: CGFloat = 260
    @State private var dragStartWidth: CGFloat = 260

    private let filterOptions = ["All", "Text", "Form"]

    var filteredNotes: [Note] {
        switch filterType {
        case "Text": return noteManager.notes.filter {
            if case .plainText = $0.content { return true }; return false
        }
        case "Form": return noteManager.notes.filter {
            if case .form = $0.content { return true }; return false
        }
        default: return noteManager.notes
        }
    }

    var selectedNote: Note? {
        guard let id = selectedNoteID else { return nil }
        return noteManager.notes.first { $0.id == id }
    }

    var body: some View {
        HStack(spacing: 0) {
            // ── LEFT PANEL ──────────────────────────────────────────
            VStack(spacing: 0) {
                // Filter strip
                HStack(spacing: 4) {
                    ForEach(filterOptions, id: \.self) { option in
                        Button(action: { filterType = option }) {
                            Text(option)
                                .font(.system(size: 10, weight: filterType == option ? .semibold : .regular))
                                .foregroundColor(filterType == option ? .primary : .secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(filterType == option ? Color.secondary.opacity(0.2) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(appSettings.theme.mainBg)

                Divider().opacity(0.3)

                // Note list
                if filteredNotes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No notes yet")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                        Text("Use the New button to create one")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(filteredNotes) { note in
                                NoteItemRow(
                                    note: note,
                                    isSelected: selectedNoteID == note.id,
                                    theme: appSettings.theme,
                                    onSelect: { selectedNoteID = note.id },
                                    onDelete: {
                                        noteManager.deleteNote(id: note.id)
                                        if selectedNoteID == note.id { selectedNoteID = filteredNotes.first(where: { $0.id != note.id })?.id }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.never)
                }

                Divider().opacity(0.3)

                // Bottom count
                HStack {
                    Text("\(filteredNotes.count) note\(filteredNotes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(appSettings.theme.panelBg)
            }
            .frame(width: leftPanelWidth)
            .background(appSettings.theme.mainBg)

            // Resize handle
            ZStack {
                Color(NSColor.separatorColor).frame(width: 1)
                Color.clear.frame(width: 8)
                    .contentShape(Rectangle())
                    .onHover { h in h ? NSCursor.resizeLeftRight.push() : NSCursor.pop() }
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
                            .onChanged { v in leftPanelWidth = max(180, min(420, dragStartWidth + v.translation.width)) }
                            .onEnded { _ in dragStartWidth = leftPanelWidth }
                    )
            }
            .frame(width: 8)

            // ── RIGHT PANEL ─────────────────────────────────────────
            Group {
                if let note = selectedNote {
                    NoteEditorView(
                        note: note,
                        noteManager: noteManager,
                        appSettings: appSettings
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.25))
                        Text("Select a note to view it")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(appSettings.theme.mainBg)
                }
            }
        }
        .background(appSettings.theme.mainBg)
        .onAppear {
            if selectedNoteID == nil { selectedNoteID = filteredNotes.first?.id }
        }
        // Listen for New Note notifications from toolbar menu
        .onReceive(NotificationCenter.default.publisher(for: .addPlainNote)) { _ in
            addNote(type: .plainText(""))
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFormNote)) { _ in
            addNote(type: .form([]))
        }
    }

    private func addNote(type: NoteContent) {
        noteManager.addNote(type: type)
        selectedNoteID = noteManager.notes.first?.id
    }
}

// MARK: - Note Item Row — title + detail strip

private let relativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f
}()

struct NoteItemRow: View {
    let note: Note
    let isSelected: Bool
    let theme: AppTheme
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private var detailCount: String {
        switch note.content {
        case .plainText(let t):
            let chars = t.count
            return "\(chars) chars"
        case .form(let items):
            return "\(items.count) field\(items.count == 1 ? "" : "s")"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // Type icon
                Image(systemName: note.content.typeIcon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    // Title
                    Text(note.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    // Detail strip: time · type · count
                    HStack(spacing: 6) {
                        // Relative time
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text(relativeFormatter.localizedString(for: note.modifiedAt, relativeTo: Date()))
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.secondary.opacity(0.7))

                        Text("·")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.4))

                        // Type badge
                        HStack(spacing: 2) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 8))
                            Text(note.content.typeName)
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.secondary.opacity(0.7))

                        Text("·")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.4))

                        // Count
                        Text(detailCount)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                Spacer(minLength: 4)

                // Hover delete
                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? theme.cardBgSelected : (isHovering ? theme.cardBgHover : theme.cardBgNormal))
                    if isSelected {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
