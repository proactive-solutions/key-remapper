import Foundation
import ServiceManagement
import Combine

/// Launch-at-login via SMAppService (macOS 13+). The main app registers itself
/// so macOS starts it automatically after boot / login.
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published private(set) var isEnabled = false
    @Published var lastError: String?

    private init() {
        refresh()
    }

    func refresh() {
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            isEnabled = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                lastError = nil
            } catch {
                lastError = error.localizedDescription
            }
            refresh()
        } else {
            lastError = "Launch at login requires macOS 13 or later."
        }
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
