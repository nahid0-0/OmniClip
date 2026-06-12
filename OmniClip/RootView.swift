import SwiftUI

/// The root view of the main NSPanel.
/// Switches between Clipboard, Notes and Settings pages
/// while keeping the same panel/toolbar structure.
struct RootView: View {
    @ObservedObject var navigation: NavigationState
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var noteManager: NoteManager
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var keyboardActions: KeyboardActionPublisher
    @ObservedObject var toolbarState: ToolbarState

    var body: some View {
        ZStack {
            switch navigation.currentPage {
            case .clipboard:
                ContentView(
                    clipboardManager: clipboardManager,
                    appSettings: appSettings,
                    keyboardActions: keyboardActions,
                    toolbarState: toolbarState
                )
                .transition(.opacity)

            case .notes:
                NotesView(
                    noteManager: noteManager,
                    appSettings: appSettings
                )
                .transition(.opacity)

            case .settings:
                SettingsView(settings: appSettings)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: navigation.currentPage)
        // Pass navigation as environment so child views can navigate
        .environmentObject(navigation)
    }
}
