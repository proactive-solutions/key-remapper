import Testing
import CoreGraphics

/// Regression tests for modifier-flag bookkeeping — the logic that makes
/// Control behave as Alt, Command as something else, etc.
///
/// A past bug left `.maskCommand` set when remapping Command to a plain
/// key; these tests pin the corrected behavior without needing Accessibility
/// permission or live key events.
@Suite("Modifier flag rewriting")
struct ModifierFlagRewriteTests {

    // MARK: - Direct remap (event's own keycode was rewritten)

    @Test("Modifier to modifier swaps flags", arguments: [
        (UInt16(59), UInt16(58)), // Left Control -> Left Option
        (UInt16(55), UInt16(59)), // Left Command -> Left Control
    ])
    func modifierToModifier(source: UInt16, destination: UInt16) {
        let current = KeyCode.flag(for: source)!
        let expected = KeyCode.flag(for: destination)!
        #expect(ModifierFlags.remapped(current: current, from: source, to: destination) == expected)
    }

    @Test("Modifier to plain key drops the source flag", arguments: [
        (UInt16(55), KeyCode.a),      // Command -> A (the past bug)
        (UInt16(57), KeyCode.escape), // Caps Lock -> Escape
    ])
    func modifierToPlainKey(source: UInt16, destination: UInt16) {
        let current = KeyCode.flag(for: source)!
        #expect(ModifierFlags.remapped(current: current, from: source, to: destination) == [])
    }

    @Test("Plain key to modifier adopts the destination flag")
    func plainKeyToModifier() {
        #expect(ModifierFlags.remapped(current: [], from: KeyCode.a, to: 55) == .maskCommand)
    }

    @Test("S to Z keeps an unrelated held Shift")
    func plainToPlainKeepsUnrelatedFlags() {
        #expect(
            ModifierFlags.remapped(current: .maskShift, from: KeyCode.s, to: KeyCode.z) == .maskShift
        )
    }

    @Test("Same-meaning remap leaves flags untouched")
    func sameFlagMapping() {
        // Left Control -> Right Control: same meaning, no change.
        #expect(
            ModifierFlags.remapped(current: .maskControl, from: 59, to: 62) == .maskControl
        )
    }

    // MARK: - Chord rewrite (event carries held modifiers, e.g. the C in Cmd+C)

    @Test("Held Command in a chord becomes Control")
    func chordCommandBecomesControl() {
        #expect(ModifierFlags.remappedChord(current: .maskCommand, using: [55: 59]) == .maskControl)
    }

    @Test("Chord rewrite preserves unmapped flags")
    func chordPreservesUnmappedFlags() {
        let result = ModifierFlags.remappedChord(current: [.maskCommand, .maskShift], using: [55: 59])
        #expect(result.contains(.maskControl))
        #expect(result.contains(.maskShift))
        #expect(!result.contains(.maskCommand))
    }

    @Test("Empty map leaves chord flags untouched")
    func chordEmptyMap() {
        #expect(ModifierFlags.remappedChord(current: .maskCommand, using: [:]) == .maskCommand)
    }
}
