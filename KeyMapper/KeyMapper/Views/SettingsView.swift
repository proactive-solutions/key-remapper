import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var remapper = KeyRemapper.shared
    @ObservedObject var loginManager = LaunchAtLoginManager.shared

    @State private var newSource: UInt16 = KeyCode.s
    @State private var newDestination: UInt16 = KeyCode.z
    @State private var captureTarget: CaptureTarget?
    @State private var permissionTrusted = PermissionsManager.isTrusted

    enum CaptureTarget: Identifiable {
        case source, destination
        var id: Int { self == .source ? 0 : 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(remapper: remapper)
            Divider()
            StatusSectionView(remapper: remapper, loginManager: loginManager)
            Divider()
            MappingsSectionView(remapper: remapper)
            Divider()
            AddMappingSectionView(
                remapper: remapper,
                newSource: $newSource,
                newDestination: $newDestination,
                onCaptureFromKey: { captureTarget = .source },
                onCaptureToKey: { captureTarget = .destination }
            )
            Divider()
            PermissionsSectionView(
                remapper: remapper,
                loginManager: loginManager,
                permissionTrusted: $permissionTrusted
            )
            FooterView()
        }
        .padding(20)
        .frame(width: 560)
        .onAppear {
            permissionTrusted = PermissionsManager.isTrusted
            loginManager.refresh()
            // LSUIElement apps don't activate on their own: claim focus so
            // the window lands in front instead of hiding behind other apps.
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                for window in NSApp.windows where window.styleMask.contains(.titled) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
        .sheet(item: $captureTarget) { target in
            VStack(spacing: 16) {
                Text(target == .source ? "Press the FROM key" : "Press the TO key")
                    .font(.headline)
                KeyCaptureView { code in
                    if target == .source { newSource = code } else { newDestination = code }
                }
                .frame(height: 60)
                Button("Done") { captureTarget = nil }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(24)
            .frame(width: 380)
        }
    }
}

#Preview {
    SettingsView()
}
