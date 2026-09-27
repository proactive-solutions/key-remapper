import CoreGraphics

/// Pure flag-computation helpers for key remapping.
///
/// Extracted from the event-tap callback so the modifier bookkeeping — the
/// most bug-prone part of remapping (e.g. Command → plain key must drop
/// `.maskCommand`) — is unit testable without Accessibility permission,
/// a runloop, or live key events. All functions are pure: same input,
/// same output, no side effects.
enum ModifierFlags {
	/// Flags that should remain on an event whose own keycode was remapped
	/// from `source` to `destination`.
	static func remapped(
		current: CGEventFlags,
		from source: UInt16,
		to destination: UInt16
	) -> CGEventFlags {
		let sourceFlag = KeyCode.flag(for: source)
		let destFlag = KeyCode.flag(for: destination)
		var flags = current
		switch (sourceFlag, destFlag) {
		case let (s?, d?) where s != d:
			// Modifier -> different modifier (e.g. Control -> Option):
			// swap the meaning.
			flags.remove(s)
			flags.insert(d)
		case (let s?, nil):
			// Modifier -> plain key (e.g. Command -> A, Caps Lock -> Escape):
			// drop the source flag so the old modifier doesn't stick.
			flags.remove(s)
		case (nil, let d?):
			// Plain key -> modifier: adopt the destination flag.
			flags.insert(d)
		default:
			break
		}
		return flags
	}

	/// Flags for an event that merely carries currently-held modifiers
	/// (e.g. the `C` in Cmd+C): every mapped modifier flag present is
	/// swapped for its destination, unmapped flags are left alone.
	static func remappedChord(current: CGEventFlags, using map: [UInt16: UInt16]) -> CGEventFlags {
		var flags = current
		for (source, destination) in map {
			guard let s = KeyCode.flag(for: source),
						let d = KeyCode.flag(for: destination),
						s != d else { continue }
			if flags.contains(s) {
				flags.remove(s)
				flags.insert(d)
			}
		}
		return flags
	}
}
