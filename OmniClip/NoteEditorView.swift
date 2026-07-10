import SwiftUI
import AppKit

// MARK: - Note Editor (right panel)

struct NoteEditorView: View {
    let note: Note
    @ObservedObject var noteManager: NoteManager
    @ObservedObject var appSettings: AppSettings

    @State private var editingTitle: String = ""
    @State private var plainText: String = ""
    @State private var newFieldValue: String = ""
    @State private var newFieldLabel: String = ""
    @State private var editingItemID: UUID? = nil
    @State private var justCopiedText: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().opacity(0.3)

            switch note.content {
            case .plainText:
                plainTextBody
            case .form(let items):
                formBody(items: items)
            }
        }
        .background(appSettings.theme.mainBg)
        .onAppear { syncState() }
    }

    private func syncState() {
        editingTitle = note.title
        if case .plainText(let t) = note.content { plainText = t }
        newFieldValue = ""
        newFieldLabel = ""
        editingItemID = nil
    }

    // MARK: - Header (always-editable title)

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: note.content.typeIcon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                // Title field — updates the left panel in real-time on every keystroke.
                // Using note.id captured at call time is safe: the ID only changes when
                // onChange(of: note.id) fires, which resets editingTitle via syncState().
                TextField("Untitled", text: $editingTitle, onCommit: {
                    saveTitle()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .onChange(of: editingTitle) { newVal in
                    let trimmed = newVal.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    // note.id is always the CURRENT note here — safe to use directly
                    noteManager.updateTitle(id: note.id, title: trimmed)
                }

                Text("Modified \(Self.dateFormatter.string(from: note.modifiedAt))")
                    .font(.system(size: 9))
                    .foregroundColor(Color.white.opacity(0.3))
            }

            Spacer()

            // Copy button — plain text notes
            if case .plainText = note.content {
                Button(action: copyPlainText) {
                    HStack(spacing: 4) {
                        Image(systemName: justCopiedText ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .medium))
                        Text(justCopiedText ? "Copied" : "Copy")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(justCopiedText ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(justCopiedText ? Color.green.opacity(0.12) : Color.white.opacity(0.07))
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: justCopiedText)
            }

            Text(note.content.typeName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.07))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(appSettings.theme.mainBg)
    }

    private func saveTitle() {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            noteManager.updateTitle(id: note.id, title: trimmed)
        } else {
            // Restore stored title if field was cleared
            editingTitle = note.title
        }
    }

    private func copyPlainText() {
        let text: String
        if case .plainText(let t) = note.content { text = t } else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        justCopiedText = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { justCopiedText = false }
    }

    // MARK: - Plain Text Body

    private var plainTextBody: some View {
        NoteTextEditor(text: $plainText, theme: appSettings.theme)
            .onChange(of: plainText) { newVal in
                noteManager.updateContent(id: note.id, content: .plainText(newVal))
            }
    }

    // MARK: - Form Body

    private func formBody(items: [FormItem]) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(items) { item in
                        FormItemRow(
                            item: item,
                            isEditing: editingItemID == item.id,
                            theme: appSettings.theme,
                            onCopy: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.value, forType: .string)
                            },
                            onEdit: { editingItemID = item.id },
                            onSave: { value, label in
                                noteManager.updateFormItem(in: note.id, itemID: item.id,
                                                           value: value, label: label)
                                editingItemID = nil
                            },
                            onDelete: {
                                noteManager.deleteFormItem(from: note.id, itemID: item.id)
                                if editingItemID == item.id { editingItemID = nil }
                            }
                        )
                    }

                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("No fields yet")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Add fields below — click the copy button on any field to copy it")
                                .font(.system(size: 10))
                                .foregroundColor(Color.secondary.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.never)

            Divider().opacity(0.3)

            addFieldBar(noteID: note.id)
        }
    }

    private func addFieldBar(noteID: UUID) -> some View {
        HStack(spacing: 8) {
            TextField("Label (optional)", text: $newFieldLabel)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1))
                .frame(maxWidth: 130)

            TextField("Value to copy…", text: $newFieldValue)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1))
                .frame(maxWidth: .infinity)

            Button(action: addField) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(newFieldValue.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.accentColor.opacity(0.4)
                                : Color.accentColor)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .disabled(newFieldValue.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(appSettings.theme.panelBg)
    }

    private func addField() {
        let val = newFieldValue.trimmingCharacters(in: .whitespaces)
        guard !val.isEmpty else { return }
        noteManager.addFormItem(to: note.id, value: val, label: newFieldLabel.trimmingCharacters(in: .whitespaces))
        newFieldValue = ""
        newFieldLabel = ""
    }
}

// MARK: - Form Item Row (click anywhere to copy)

struct FormItemRow: View {
    let item: FormItem
    let isEditing: Bool
    let theme: AppTheme
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onSave: (String, String) -> Void
    let onDelete: () -> Void

    @State private var editValue: String = ""
    @State private var editLabel: String = ""
    @State private var isHovering: Bool = false
    @State private var justCopied: Bool = false

    var body: some View {
        Group {
            if isEditing {
                editRow
            } else {
                displayRow
            }
        }
        .onAppear {
            editValue = item.value
            editLabel = item.label
        }
    }

    private var displayRow: some View {
        Button(action: {
            // Click anywhere on the row to copy
            onCopy()
            justCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { justCopied = false }
        }) {
            HStack(spacing: 10) {
                // Copy icon — shows checkmark when just copied
                ZStack {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(justCopied ? .green : .accentColor)
                }
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(justCopied ? 0.15 : 0.10))
                .cornerRadius(4)
                .animation(.easeInOut(duration: 0.2), value: justCopied)

                // Label + value
                VStack(alignment: .leading, spacing: 1) {
                    if !item.label.isEmpty {
                        Text(item.label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    Text(item.value)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                Spacer()

                // Edit / delete on hover
                if isHovering {
                    HStack(spacing: 4) {
                        Button(action: {
                            editValue = item.value
                            editLabel = item.label
                            onEdit()
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(width: 22, height: 22)
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(width: 22, height: 22)
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(justCopied ? Color.accentColor.opacity(0.08) : (isHovering ? theme.cardBgHover : theme.cardBgNormal))
            )
            .animation(.easeInOut(duration: 0.2), value: justCopied)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var editRow: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Label (optional)", text: $editLabel)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(3)

                TextField("Value", text: $editValue)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(3)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1))
            }

            VStack(spacing: 4) {
                Button(action: { onSave(editValue, editLabel) }) {
                    Text("Save")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Button(action: { onSave(item.value, item.label) }) {
                    Text("Cancel")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(theme.cardBgSelected)
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
        )
    }
}

// MARK: - Plain text NSTextView for notes

struct NoteTextEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: AppTheme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let tv = scrollView.documentView as! NSTextView
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.font = NSFont.systemFont(ofSize: 13)
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.textContainerInset = NSSize(width: 16, height: 16)
        tv.drawsBackground = true
        applyTheme(tv)
        tv.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let tv = scrollView.documentView as! NSTextView
        applyTheme(tv)
        // Only replace the text when the note changes externally (e.g. note selection changed),
        // NOT when the user is actively typing (which would clobber the cursor position).
        guard !context.coordinator.isEditing else { return }
        if tv.string != text {
            tv.string = text
        }
    }

    private func applyTheme(_ tv: NSTextView) {
        let bg = theme.nsEditorBg
        tv.backgroundColor = bg
        tv.enclosingScrollView?.backgroundColor = bg
        tv.textColor = .labelColor
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoteTextEditor
        /// True while the user is actively editing — prevents updateNSView from resetting text.
        var isEditing: Bool = false

        init(_ p: NoteTextEditor) { parent = p }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidChange(_ n: Notification) {
            guard let tv = n.object as? NSTextView else { return }
            isEditing = true
            parent.text = tv.string
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }
    }
}
