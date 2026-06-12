import SwiftUI
import AppKit

// MARK: - Notes Window Root

struct NotesView: View {
    @ObservedObject var noteManager: NoteManager
    @ObservedObject var appSettings: AppSettings

    @State private var selectedNoteID: UUID?
    @State private var filterType: String = "All"   // All / Text / Form
    @State private var leftPanelWidth: CGFloat = 280
    @State private var dragStartWidth: CGFloat = 280
    @State private var showNewNoteMenu: Bool = false

    private let filterOptions = ["All", "Text", "Form"]

    var filteredNotes: [Note] {
        switch filterType {
        case "Text": return noteManager.notes.filter { if case .plainText = $0.content { return true }; return false }
        case "Form": return noteManager.notes.filter { if case .form = $0.content { return true }; return false }
        default:     return noteManager.notes
        }
    }

    var selectedNote: Note? {
        guard let id = selectedNoteID else { return nil }
        return noteManager.notes.first { $0.id == id }
    }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT PANEL
            VStack(spacing: 0) {
                // Toolbar strip
                HStack(spacing: 6) {
                    Text("Notes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Filter pills
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

                    // New Note menu
                    Menu {
                        Button(action: { addNote(type: .plainText("")) }) {
                            Label("Plain Text Note", systemImage: "doc.text")
                        }
                        Button(action: { addNote(type: .form([])) }) {
                            Label("Form Note", systemImage: "list.bullet.clipboard")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text("New")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor)
                        .cornerRadius(4)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 52, height: 22)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(appSettings.theme.panelBg)

                Divider().opacity(0.3)

                // Note list
                if filteredNotes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No notes yet")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text("Press New to create one")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(filteredNotes) { note in
                                NoteItemRow(
                                    note: note,
                                    isSelected: selectedNoteID == note.id,
                                    theme: appSettings.theme,
                                    onSelect: { selectedNoteID = note.id },
                                    onDelete: { noteManager.deleteNote(id: note.id)
                                        if selectedNoteID == note.id { selectedNoteID = nil }
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

                // Bottom status
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
                            .onChanged { v in
                                leftPanelWidth = max(200, min(500, dragStartWidth + v.translation.width))
                            }
                            .onEnded { _ in dragStartWidth = leftPanelWidth }
                    )
            }
            .frame(width: 8)

            // RIGHT PANEL
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
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.3))
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
            // Auto-select first note
            if selectedNoteID == nil { selectedNoteID = filteredNotes.first?.id }
        }
    }

    private func addNote(type: NoteContent) {
        noteManager.addNote(type: type)
        selectedNoteID = noteManager.notes.first?.id
    }
}

// MARK: - Note Item Row (left panel card)

struct NoteItemRow: View {
    let note: Note
    let isSelected: Bool
    let theme: AppTheme
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .abbreviated; return f
    }()

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                // Type icon
                Image(systemName: note.content.typeIcon)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    // Title + type badge
                    HStack(spacing: 6) {
                        Text(note.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 4)

                        Text(note.content.typeName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(3)
                    }

                    // Preview
                    Text(note.preview.isEmpty ? "Empty note" : note.preview)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Date
                    Text(Self.relativeDateFormatter.localizedString(for: note.modifiedAt, relativeTo: Date()))
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.3))
                }

                // Hover delete
                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isSelected
                              ? theme.cardBgSelected
                              : (isHovering ? theme.cardBgHover : theme.cardBgNormal))
                    if isSelected {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
