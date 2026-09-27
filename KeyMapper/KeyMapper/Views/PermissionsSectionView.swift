import SwiftUI

struct PermissionsSectionView: View {
    @ObservedObject var remapper: KeyRemapper
    @ObservedObject var loginManager: LaunchAtLoginManager
    @Binding var permissionTrusted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Permissions")
                .font(.headline)
            HStack {
                Image(systemName: permissionTrusted ? "checkmark.shield.fill" : "exclamationmark.shield")
                    .foregroundColor(permissionTrusted ? .green : .red)
                Text(permissionTrusted
                     ? "Accessibility permission granted."
                     : "Accessibility permission required for system-wide remapping.")
                Spacer()
                if !permissionTrusted {
                    Button("Request…") {
                        PermissionsManager.requestTrust()
                    }
                }
                Button("Open Settings") {
                    PermissionsManager.openAccessibilitySettings()
                }
            }
            .font(.callout)
            if let error = remapper.lastError {
                Text(error).font(.caption).foregroundColor(.red)
            }
            if let loginError = loginManager.lastError {
                Text(loginError).font(.caption).foregroundColor(.red)
            }
            Button("Refresh status") {
                permissionTrusted = PermissionsManager.isTrusted
                loginManager.refresh()
                if remapper.isRunning == false && permissionTrusted {
                    _ = remapper.start()
                }
            }
            .font(.callout)
            Text("System Settings → Privacy & Security → Accessibility → enable KeyMapper. Then toggle Enabled off/on. On some macOS versions also allow Input Monitoring.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
