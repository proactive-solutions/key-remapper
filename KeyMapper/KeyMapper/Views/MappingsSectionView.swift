import SwiftUI

struct MappingsSectionView: View {
    @ObservedObject var remapper: KeyRemapper

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Key mappings")
                    .font(.headline)
                Spacer()
                Button("Reset to examples") { remapper.resetToDefaults() }
                    .buttonStyle(.link)
                    .font(.callout)
            }
            if remapper.mappings.isEmpty {
                Text("No mappings yet. Add one below.")
                    .foregroundColor(.secondary)
            } else {
                ForEach($remapper.mappings) { $mapping in
                    HStack {
                        Toggle("", isOn: $mapping.isEnabled)
                            .labelsHidden()
                            .onChange(of: mapping.isEnabled) { _, _ in remapper.restart() }
                        Picker("", selection: $mapping.sourceKeyCode) {
                            ForEach(KeyCode.all, id: \.code) { item in
                                Text(item.name).tag(item.code)
                            }
                        }
                        .frame(width: 170)
                        .onChange(of: mapping.sourceKeyCode) { _, _ in remapper.restart() }

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)

                        Picker("", selection: $mapping.destinationKeyCode) {
                            ForEach(KeyCode.all, id: \.code) { item in
                                Text(item.name).tag(item.code)
                            }
                        }
                        .frame(width: 170)
                        .onChange(of: mapping.destinationKeyCode) { _, _ in remapper.restart() }

                        Spacer()
                        Button {
                            remapper.removeMapping(mapping)
                            remapper.restart()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Delete mapping")
                    }
                }
            }
            Text("Examples: S → Z · Left Control → Left Option (Alt) · Caps Lock → Escape · F1 → A · Right Command → Right Control")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
