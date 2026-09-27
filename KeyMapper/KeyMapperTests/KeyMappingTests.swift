import Foundation
import Testing

/// Mapping model tests: default presets shipped on first launch and
/// persistence round-trip through Codable.
@Suite("Mapping model")
struct KeyMappingTests {

    @Test("Default presets contain the requested examples", arguments: [
        (KeyCode.s, KeyCode.z),
        (KeyCode.controlLeft, KeyCode.optionLeft),
        (KeyCode.capsLock, KeyCode.escape),
        (KeyCode.f1, KeyCode.a),
    ])
    func defaultPresets(source: UInt16, destination: UInt16) {
        #expect(KeyMapping.defaultPresets.count == 4)
        let hasPreset = KeyMapping.defaultPresets.contains {
            $0.sourceKeyCode == source && $0.destinationKeyCode == destination
        }
        #expect(hasPreset)
        let allEnabled = KeyMapping.defaultPresets.allSatisfy(\.isEnabled)
        #expect(
            allEnabled,
            "Presets must be enabled out of the box"
        )
    }

    @Test("Codable round-trip preserves the mapping")
    func codableRoundTrip() throws {
        let original = KeyMapping(sourceKeyCode: 55, destinationKeyCode: 59) // Command -> Control
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(KeyMapping.self, from: data) == original)
    }

    @Test("Names resolve through the keycode table")
    func names() {
        let mapping = KeyMapping(sourceKeyCode: KeyCode.s, destinationKeyCode: KeyCode.z)
        #expect(mapping.sourceName == "S")
        #expect(mapping.destinationName == "Z")
    }
}
