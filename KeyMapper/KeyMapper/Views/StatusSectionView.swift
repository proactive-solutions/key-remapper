import SwiftUI

struct StatusSectionView: View {
    @ObservedObject var remapper: KeyRemapper
    @ObservedObject var loginManager: LaunchAtLoginManager

    var body: some View {
        HStack(spacing: 16) {
            Label(
                remapper.isRunning ? "Remapping active" : "Remapping paused",
                systemImage: remapper.isRunning ? "checkmark.circle.fill" : "pause.circle"
            )
            .foregroundColor(remapper.isRunning ? .green : .orange)

            Spacer()

            Toggle("Launch at login", isOn: Binding(
                get: { loginManager.isEnabled },
                set: { loginManager.setEnabled($0) }
            ))
            .help("Start KeyMapper automatically when macOS boots (SMAppService login item).")
        }
        .font(.callout)
    }
}
