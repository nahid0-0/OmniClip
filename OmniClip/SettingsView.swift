import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Behavior section
            VStack(alignment: .leading, spacing: 12) {
                Text("BEHAVIOR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Copy on single click", isOn: $settings.copyOnClick)
                    .toggleStyle(.checkbox)
                
                Toggle("Show timestamps", isOn: $settings.showTimestamps)
                    .toggleStyle(.checkbox)
                
                Toggle("Capture screenshots", isOn: $settings.captureScreenshots)
                    .toggleStyle(.checkbox)
            }
            
            Divider()
            
            // About section
            VStack(alignment: .leading, spacing: 12) {
                Text("ABOUT")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("OmniClip")
                    Spacer()
                    Text("macOS Clipboard Manager")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                HStack {
                    Text("Source Code")
                    Spacer()
                    Button(action: {
                        if let url = URL(string: "https://github.com/nahid0-0/OmniClip") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                            Text("GitHub")
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 320, height: 320)
    }
}
