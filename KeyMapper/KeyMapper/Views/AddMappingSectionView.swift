import SwiftUI

struct AddMappingSectionView: View {
    @ObservedObject var remapper: KeyRemapper
    @Binding var newSource: UInt16
    @Binding var newDestination: UInt16
    var onCaptureFromKey: () -> Void
    var onCaptureToKey: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add mapping")
                .font(.headline)
            HStack {
                Picker("From", selection: $newSource) {
                    ForEach(KeyCode.all, id: \.code) { item in
                        Text(item.name).tag(item.code)
                    }
                }
                .frame(width: 180)
                Image(systemName: "arrow.right")
                Picker("To", selection: $newDestination) {
                    ForEach(KeyCode.all, id: \.code) { item in
                        Text(item.name).tag(item.code)
                    }
                }
                .frame(width: 180)
                Button("Add") {
                    remapper.addMapping(source: newSource, destination: newDestination)
                    remapper.restart()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSource == newDestination)
            }
            HStack {
                Button("Press FROM key…", action: onCaptureFromKey)
                Button("Press TO key…", action: onCaptureToKey)
                Spacer()
            }
            .font(.callout)
        }
    }
}
