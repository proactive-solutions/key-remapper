import Testing
import CoreGraphics

/// Keycode table tests: modifier-flag lookup, display names, and picker
/// coverage. Guards regressions like Command keys silently missing from
/// the remapping UI.
@Suite("Keycode table")
struct KeyCodeTests {

    @Test("Modifier keys map to their event flags", arguments: [
        (UInt16(59), CGEventFlags.maskControl),   // Left Control
        (UInt16(62), CGEventFlags.maskControl),   // Right Control
        (UInt16(58), CGEventFlags.maskAlternate), // Left Option
        (UInt16(61), CGEventFlags.maskAlternate), // Right Option
        (UInt16(55), CGEventFlags.maskCommand),   // Left Command
        (UInt16(54), CGEventFlags.maskCommand),   // Right Command
        (UInt16(56), CGEventFlags.maskShift),     // Left Shift
        (UInt16(60), CGEventFlags.maskShift),     // Right Shift
        (UInt16(57), CGEventFlags.maskAlphaShift), // Caps Lock
        (UInt16(63), CGEventFlags.maskSecondaryFn), // Fn
    ])
    func modifierFlags(code: UInt16, expected: CGEventFlags) {
        #expect(KeyCode.flag(for: code) == expected)
    }

    @Test("Plain keys have no modifier flag", arguments: [
        KeyCode.s, KeyCode.a, KeyCode.z, KeyCode.f1, KeyCode.escape, KeyCode.space,
    ])
    func plainKeys(code: UInt16) {
        #expect(KeyCode.flag(for: code) == nil)
    }

    @Test("Remappable keys are selectable in pickers", arguments: [
        (UInt16(55), "Left Command"), (UInt16(54), "Right Command"), (UInt16(57), "Caps Lock"),
        (UInt16(59), "Left Control"), (UInt16(122), "F1"),
    ])
    func pickerPresence(code: UInt16, name: String) {
        let codes = Set(KeyCode.all.map(\.code))
        #expect(codes.contains(code), "\(name) must be selectable")
    }

    @Test("Display names resolve through the table")
    func displayNames() {
        #expect(KeyCode.displayName(for: 1) == "S (1)")
        #expect(KeyCode.displayName(for: 55).contains("Command"))
        #expect(KeyCode.displayName(for: 200) == "Key 200")
    }
}
