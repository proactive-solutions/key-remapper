import AppKit
import SwiftUI

/// Background menu-bar app: no Dock icon (LSUIElement), lives in the menu bar,
/// auto-starts the event tap, and offers a Settings window for editing mappings.
@main
struct KeyMapperApp: App {
    @ObservedObject private var remapper = KeyRemapper.shared
    @ObservedObject private var loginManager = LaunchAtLoginManager.shared
    @State private var permissionTrusted = PermissionsManager.isTrusted
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("KeyMapper", systemImage: menuIcon) {
            Text("KeyMapper — \(remapper.isRunning ? "Active" : "Paused")")
                .font(.headline)
            Divider()
            Button(remapper.isRunning ? "Pause remapping" : "Start remapping") {
                if remapper.isRunning {
                    remapper.stop()
                } else {
                    if PermissionsManager.isTrusted {
                        _ = remapper.start()
                    } else {
                        PermissionsManager.requestTrust()
                        openAndFocusSettings()
                    }
                }
                permissionTrusted = PermissionsManager.isTrusted
            }
            Button("Open Settings…") {
                openAndFocusSettings()
            }
            Button("Quit KeyMapper") {
                remapper.stop()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .onAppear {
                    permissionTrusted = PermissionsManager.isTrusted
                    // Auto-start when permission is available.
                    if permissionTrusted, !remapper.isRunning {
                        _ = remapper.start()
                    }
                }
        }
    }

    private var menuIcon: String {
        remapper.isRunning ? "keyboard.fill" : "keyboard"
    }

    /// Opens the Settings window and brings it to the front.
    /// Needed because an LSUIElement (background, no-Dock) app does not
    /// activate itself when showing Settings — without this the window can
    /// open behind the current app and appear lost.
    private func openAndFocusSettings() {
        openSettings()
        // The Settings window is materialized asynchronously, so focusing
        // must happen on the next run-loop turn, after it exists.
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows where window.styleMask.contains(.titled) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

