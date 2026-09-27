import SwiftUI

struct HeaderView: View {
    @ObservedObject var remapper: KeyRemapper

    var body: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading) {
                Text("KeyMapper")
                    .font(.title2).bold()
                Text("System-wide key remapping · runs in menu bar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("Enabled", isOn: Binding(
                get: { remapper.isRunning },
                set: { on in on ? _ = remapper.start() : remapper.stop() }
            ))
            .toggleStyle(.switch)
        }
    }
}
