import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var clipboardManager: ClipboardManager!
    private var appSettings: AppSettings!
    private var settingsObserver: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize settings and clipboard manager
        appSettings = AppSettings()
        clipboardManager = ClipboardManager()
        
        // Configure screenshot watcher based on initial settings
        clipboardManager.configureScreenshotWatcher(enabled: appSettings.captureScreenshots)
        
        // Observe settings changes
        settingsObserver = appSettings.$captureScreenshots.sink { [weak self] enabled in
            self?.clipboardManager.configureScreenshotWatcher(enabled: enabled)
        }
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            button.image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "OmniClip")?.withSymbolConfiguration(config)
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 700, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView(clipboardManager: clipboardManager, appSettings: appSettings)
        )
    }
    
    @objc func togglePopover(_ sender: Any?) {
        // Check if right-click for context menu
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }
        
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Activate app to give focus
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit OmniClip", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "OmniClip Settings"
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView(settings: appSettings))
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardManager.stopMonitoring()
    }
}
