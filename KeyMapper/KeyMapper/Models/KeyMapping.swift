import CoreGraphics
import Foundation

/// A single key-to-key remapping: source keycode behaves as destination keycode.
struct KeyMapping: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var sourceKeyCode: UInt16
    var destinationKeyCode: UInt16
    var isEnabled: Bool = true

    var sourceName: String { KeyCode.names[Int(sourceKeyCode)] ?? "Key \(sourceKeyCode)" }
    var destinationName: String { KeyCode.names[Int(destinationKeyCode)] ?? "Key \(destinationKeyCode)" }
}

/// macOS virtual keycodes (Carbon / CGKeyboardEvent).
/// Source: HIToolbox/Events.h  (kVK_* constants).
enum KeyCode {
    // Letters
    static let a: UInt16 = 0
    static let s: UInt16 = 1
    static let d: UInt16 = 2
    static let f: UInt16 = 3
    static let h: UInt16 = 4
    static let g: UInt16 = 5
    static let z: UInt16 = 6
    static let x: UInt16 = 7
    static let c: UInt16 = 8
    static let v: UInt16 = 9
    static let b: UInt16 = 11
    static let q: UInt16 = 12
    static let w: UInt16 = 13
    static let e: UInt16 = 14
    static let r: UInt16 = 15
    static let y: UInt16 = 16
    static let t: UInt16 = 17
    static let one: UInt16 = 18
    static let two: UInt16 = 19
    static let three: UInt16 = 20
    static let four: UInt16 = 21
    static let six: UInt16 = 22
    static let five: UInt16 = 23
    static let equal: UInt16 = 24
    static let nine: UInt16 = 25
    static let seven: UInt16 = 26
    static let minus: UInt16 = 27
    static let eight: UInt16 = 28
    static let zero: UInt16 = 29
    static let rightBracket: UInt16 = 30
    static let o: UInt16 = 31
    static let u: UInt16 = 32
    static let leftBracket: UInt16 = 33
    static let i: UInt16 = 34
    static let p: UInt16 = 35
    static let l: UInt16 = 37
    static let j: UInt16 = 38
    static let quote: UInt16 = 39
    static let k: UInt16 = 40
    static let semicolon: UInt16 = 41
    static let backslash: UInt16 = 42
    static let comma: UInt16 = 43
    static let slash: UInt16 = 44
    static let n: UInt16 = 45
    static let m: UInt16 = 46
    static let period: UInt16 = 47
    static let tab: UInt16 = 48
    static let space: UInt16 = 49
    static let grave: UInt16 = 50
    static let delete: UInt16 = 51
    static let escape: UInt16 = 53
    static let commandLeft: UInt16 = 55
    static let shiftLeft: UInt16 = 56
    static let capsLock: UInt16 = 57
    static let optionLeft: UInt16 = 58
    static let controlLeft: UInt16 = 59
    static let shiftRight: UInt16 = 60
    static let optionRight: UInt16 = 61
    static let controlRight: UInt16 = 62
    static let commandRight: UInt16 = 54
    static let fn: UInt16 = 63
    static let f17: UInt16 = 64
    static let keypadDecimal: UInt16 = 65
    static let keypadMultiply: UInt16 = 67
    static let keypadPlus: UInt16 = 69
    static let keypadClear: UInt16 = 71
    static let volumeUp: UInt16 = 72
    static let volumeDown: UInt16 = 73
    static let mute: UInt16 = 74
    static let keypadDivide: UInt16 = 75
    static let keypadEnter: UInt16 = 76
    static let keypadMinus: UInt16 = 78
    static let f18: UInt16 = 79
    static let f19: UInt16 = 80
    static let keypadEqual: UInt16 = 81
    static let keypad0: UInt16 = 82
    static let keypad1: UInt16 = 83
    static let keypad2: UInt16 = 84
    static let keypad3: UInt16 = 85
    static let keypad4: UInt16 = 86
    static let keypad5: UInt16 = 87
    static let keypad6: UInt16 = 88
    static let keypad7: UInt16 = 89
    static let f20: UInt16 = 90
    static let keypad8: UInt16 = 91
    static let keypad9: UInt16 = 92
    static let f5: UInt16 = 96
    static let f6: UInt16 = 97
    static let f7: UInt16 = 98
    static let f3: UInt16 = 99
    static let f8: UInt16 = 100
    static let f9: UInt16 = 101
    static let f11: UInt16 = 103
    static let f13: UInt16 = 105
    static let f16: UInt16 = 102
    static let f14: UInt16 = 107
    static let f10: UInt16 = 109
    static let f12: UInt16 = 111
    static let f15: UInt16 = 113
    static let home: UInt16 = 115
    static let pageUp: UInt16 = 116
    static let forwardDelete: UInt16 = 117
    static let f4: UInt16 = 118
    static let end: UInt16 = 119
    static let f2: UInt16 = 120
    static let pageDown: UInt16 = 121
    static let f1: UInt16 = 122
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let downArrow: UInt16 = 125
    static let upArrow: UInt16 = 126
    static let returnKey: UInt16 = 36

    /// All remappable keycodes with display names, sorted for pickers.
    static let all: [(code: UInt16, name: String)] = {
        var items = names.enumerated().compactMap { idx, name -> (UInt16, String)? in
            guard let name else { return nil }
            return (UInt16(idx), name)
        }
        items.sort { $0.1 < $1.1 }
        return items
    }()

    /// Index = keycode. Sparse — nil means unnamed/reserved.
    static let names: [String?] = {
        var n = [String?](repeating: nil, count: 256)
        func set(_ code: UInt16, _ name: String) { n[Int(code)] = name }
        set(0, "A"); set(1, "S"); set(2, "D"); set(3, "F")
        set(4, "H"); set(5, "G"); set(6, "Z"); set(7, "X")
        set(8, "C"); set(9, "V"); set(11, "B"); set(12, "Q")
        set(13, "W"); set(14, "E"); set(15, "R"); set(16, "Y")
        set(17, "T"); set(18, "1"); set(19, "2"); set(20, "3")
        set(21, "4"); set(22, "6"); set(23, "5"); set(24, "=")
        set(25, "9"); set(26, "7"); set(27, "-"); set(28, "8")
        set(29, "0"); set(30, "]"); set(31, "O"); set(32, "U")
        set(33, "["); set(34, "I"); set(35, "P"); set(36, "Return")
        set(37, "L"); set(38, "J"); set(39, "'"); set(40, "K")
        set(41, ";"); set(42, "\\"); set(43, ","); set(44, "/")
        set(45, "N"); set(46, "M"); set(47, "."); set(48, "Tab")
        set(49, "Space"); set(50, "`"); set(51, "Delete"); set(53, "Escape")
        set(54, "Right Command"); set(55, "Left Command")
        set(56, "Left Shift"); set(57, "Caps Lock")
        set(58, "Left Option (Alt)"); set(59, "Left Control")
        set(60, "Right Shift"); set(61, "Right Option (Alt)")
        set(62, "Right Control"); set(63, "Fn")
        set(64, "F17"); set(72, "Volume Up"); set(73, "Volume Down")
        set(74, "Mute"); set(96, "F5"); set(97, "F6"); set(98, "F7")
        set(99, "F3"); set(100, "F8"); set(101, "F9"); set(102, "F16")
        set(103, "F11"); set(105, "F13"); set(107, "F14")
        set(109, "F10"); set(111, "F12"); set(113, "F15")
        set(115, "Home"); set(116, "Page Up"); set(117, "Forward Delete")
        set(118, "F4"); set(119, "End"); set(120, "F2")
        set(121, "Page Down"); set(122, "F1")
        set(123, "Left Arrow"); set(124, "Right Arrow")
        set(125, "Down Arrow"); set(126, "Up Arrow")
        set(79, "F18"); set(80, "F19"); set(90, "F20")
        return n
    }()

    /// CGEventFlags mask for a modifier keycode, if it is a modifier.
    static func flag(for keyCode: UInt16) -> CGEventFlags? {
        switch keyCode {
        case 59, 62: return .maskControl
        case 58, 61: return .maskAlternate
        case 55, 54: return .maskCommand
        case 56, 60: return .maskShift
        case 57: return .maskAlphaShift
        case 63: return .maskSecondaryFn
        default: return nil
        }
    }

    static func displayName(for keyCode: UInt16) -> String {
        if Int(keyCode) < names.count, let name = names[Int(keyCode)] {
            return "\(name) (\(keyCode))"
        }
        return "Key \(keyCode)"
    }
}

// Default presets matching the requested examples.
extension KeyMapping {
    static var defaultPresets: [KeyMapping] {
        [
            KeyMapping(sourceKeyCode: KeyCode.s, destinationKeyCode: KeyCode.z),
            KeyMapping(sourceKeyCode: KeyCode.controlLeft, destinationKeyCode: KeyCode.optionLeft),
            KeyMapping(sourceKeyCode: KeyCode.capsLock, destinationKeyCode: KeyCode.escape),
            KeyMapping(sourceKeyCode: KeyCode.f1, destinationKeyCode: KeyCode.a),
        ]
    }
}
