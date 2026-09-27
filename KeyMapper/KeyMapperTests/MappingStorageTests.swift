import Foundation
import Testing

/// Regression test for the "each mapping adds ~4 MB" report.
///
/// A mapping is a few dozen bytes of JSON. Mapping edits must never churn
/// the event tap (Mach port + runloop source + thread per restart), so this
/// locks in the invariant that stored mappings stay tiny no matter how many
/// the user adds.
@Suite("Mapping storage footprint")
struct MappingStorageTests {

    @Test("500 mappings persist as kilobytes, not megabytes")
    func manyMappingsStayTiny() throws {
        var mappings: [KeyMapping] = []
        mappings.reserveCapacity(500)
        for i in 0..<500 {
            mappings.append(KeyMapping(
                sourceKeyCode: UInt16(i % 128),
                destinationKeyCode: UInt16((i + 1) % 128)
            ))
        }
        let data = try JSONEncoder().encode(mappings)
        #expect(data.count < 256 * 1024, "500 mappings must be KBs, got \(data.count) bytes")
    }

    @Test("A single mapping is tens of bytes")
    func singleMappingIsBytes() throws {
        let data = try JSONEncoder().encode(
            KeyMapping(sourceKeyCode: KeyCode.s, destinationKeyCode: KeyCode.z)
        )
        #expect(data.count < 1024, "one mapping must be < 1 KB, got \(data.count) bytes")
    }
}
