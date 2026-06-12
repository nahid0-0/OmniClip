import SwiftUI
import AppKit

struct AddClipView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var appSettings: AppSettings
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var content: String = ""
    @FocusState private var contentFocused: Bool

    // Auto-number label shown as placeholder
    private var autoTitle: String {
        let count = clipboardManager.clips.count + 1
        return "Item \(count)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Clip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Manually add a clip to your history")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(appSettings.theme.panelBg)

            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Title", systemImage: "tag")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        TextField(autoTitle, text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }

                    // Content field
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Content", systemImage: "text.alignleft")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        AddClipTextEditor(text: $content, theme: appSettings.theme)
                            .frame(minHeight: 160)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                }
                .padding(16)
            }

            Divider().opacity(0.3)

            // Action bar
            HStack(spacing: 8) {
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: save) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                        Text("Add Clip")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.accentColor.opacity(0.4)
                                : Color.accentColor)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(appSettings.theme.panelBg)
        }
        .background(appSettings.theme.mainBg)
    }

    private func save() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        clipboardManager.insertManual(title: title, text: trimmed)
        onDismiss()
    }
}

// MARK: - Simple NSTextView wrapper for multi-line input

struct AddClipTextEditor: NSViewRepresentable {
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
        tv.textContainerInset = NSSize(width: 10, height: 10)
        tv.drawsBackground = true
        applyTheme(tv)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let tv = scrollView.documentView as! NSTextView
        applyTheme(tv)
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
        var parent: AddClipTextEditor
        init(_ p: AddClipTextEditor) { parent = p }
        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}
