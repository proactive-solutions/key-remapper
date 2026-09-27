import Cocoa
import Combine

/// System-wide key remapping engine built on CGEventTap.
///
/// Intercepts keyDown / keyUp / flagsChanged at the session tap and rewrites
/// keycodes + modifier flags according to the active mappings.
///
/// Requirements at runtime:
/// - Accessibility permission (AXIsProcessTrusted). Without it the tap cannot
///   be created and start() returns false.
/// - The app must stay alive in the background (LSUIElement + menu bar).
final class KeyRemapper: ObservableObject {
	static let shared = KeyRemapper()

	@Published var mappings: [KeyMapping] = [] {
		didSet { persist() }
	}
	@Published private(set) var isRunning = false
	@Published var lastError: String?

	private var eventTap: CFMachPort?
	private var runLoopSource: CFRunLoopSource?
	private var tapThread: Thread?
	private var tapRunLoop: CFRunLoop?
	private var restartWorkItem: DispatchWorkItem?

	private let storageKey = "KeyMapper.mappings.v1"

	private init() {
		load()
	}

	// MARK: - Persistence

	private func load() {
		if let data = UserDefaults.standard.data(forKey: storageKey),
			 let decoded = try? JSONDecoder().decode([KeyMapping].self, from: data),
			 !decoded.isEmpty {
			mappings = decoded
		} else {
			mappings = KeyMapping.defaultPresets
		}
	}

	private func persist() {
		if let data = try? JSONEncoder().encode(mappings) {
			UserDefaults.standard.set(data, forKey: storageKey)
		}
	}

	/// Fast lookup of enabled mappings.
	private func activeMap() -> [UInt16: UInt16] {
		var map = [UInt16: UInt16]()
		for m in mappings where m.isEnabled && m.sourceKeyCode != m.destinationKeyCode {
			map[m.sourceKeyCode] = m.destinationKeyCode
		}
		return map
	}

	// MARK: - Start / Stop

	/// Starts the event tap. Returns false if permission is missing or tap creation fails.
	@discardableResult
	func start() -> Bool {
		if isRunning || eventTap != nil { return true }
		// A restart() may have scheduled a deferred start; a direct start()
		// supersedes it — drop the stale item so we never create two taps.
		restartWorkItem?.cancel()
		restartWorkItem = nil
		guard PermissionsManager.isTrusted else {
			lastError = "Accessibility permission is required. Enable it in System Settings → Privacy & Security → Accessibility."
			return false
		}

		let mask: CGEventMask =
		(1 << CGEventType.keyDown.rawValue) |
		(1 << CGEventType.keyUp.rawValue) |
		(1 << CGEventType.flagsChanged.rawValue)

		// Retain self for the C callback without a retain cycle on stop.
		let ref = Unmanaged.passUnretained(self).toOpaque()
		guard let tap = CGEvent.tapCreate(
			tap: .cgSessionEventTap,
			place: .headInsertEventTap,
			options: .defaultTap,
			eventsOfInterest: mask,
			callback: { proxy, type, event, refcon in
				guard let refcon else { return Unmanaged.passUnretained(event) }
				let remapper = Unmanaged<KeyRemapper>.fromOpaque(refcon).takeUnretainedValue()
				return remapper.handleEvent(proxy: proxy, type: type, event: event)
			},
			userInfo: ref
		) else {
			lastError = "Could not create event tap. Check Accessibility permission, then relaunch."
			return false
		}

		eventTap = tap
		runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

		let thread = Thread { [weak self] in
			guard let self, let source = self.runLoopSource else { return }
			let runLoop = CFRunLoopGetCurrent()
			self.tapRunLoop = runLoop
			CFRunLoopAddSource(runLoop, source, .commonModes)
			CGEvent.tapEnable(tap: tap, enable: true)
			CFRunLoopRun()
			// CFRunLoopStop() (from stop()) lands here: detach the source so
			// the thread can deallocate instead of lingering forever.
			// Without this, every restart() leaked one thread (≈512 KB stack),
			// so memory grew on each remap change.
			CFRunLoopRemoveSource(runLoop, source, .commonModes)
		}
		thread.qualityOfService = .userInteractive
		thread.name = "KeyMapper.EventTap"
		tapThread = thread
		thread.start()

		DispatchQueue.main.async { self.isRunning = true; self.lastError = nil }
		return true
	}

	func stop() {
		// Drop any queued restart so a stale deferred start() can't fire
		// after this stop and leak a second tap.
		restartWorkItem?.cancel()
		restartWorkItem = nil
		if let tap = eventTap {
			CGEvent.tapEnable(tap: tap, enable: false)
			CFMachPortInvalidate(tap)
		}
		eventTap = nil
		if let source = runLoopSource {
			CFRunLoopSourceInvalidate(source)
		}
		runLoopSource = nil
		// The tap thread is blocked in CFRunLoopRun(). Thread.cancel() alone
		// only sets isCancelled — the runloop keeps running and the thread
		// (plus its stack) leaks. Stop + wake the runloop so the thread
		// returns from CFRunLoopRun() and exits.
		if let runLoop = tapRunLoop {
			CFRunLoopStop(runLoop)
			CFRunLoopWakeUp(runLoop)
		}
		tapRunLoop = nil
		tapThread?.cancel()
		tapThread = nil
		DispatchQueue.main.async { self.isRunning = false }
	}

	/// Bounces the event tap. Only needed to recover a dead tap — NOT for
	/// mapping edits: handleEvent rebuilds its lookup from live `mappings`
	/// on every key event, so adds/toggles/removals apply instantly with the
	/// tap left running. Call start() (a no-op when live) from CRUD paths
	/// instead; each teardown/setup cycle churns a Mach port, runloop
	/// source and thread (~MBs), which is what made memory grow per mapping.
	func restart() {
		stop()
		// Debounce: picker/toggle changes can fire restart() several times in
		// quick succession. Coalesce them into one deferred start so we don't
		// stack up multiple taps/threads.
		restartWorkItem?.cancel()
		let work = DispatchWorkItem { [weak self] in _ = self?.start() }
		restartWorkItem = work
		// Small delay so the old tap thread tears down before recreating.
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
	}

	// MARK: - CRUD helpers

	func addMapping(source: UInt16, destination: UInt16) {
		mappings.append(KeyMapping(sourceKeyCode: source, destinationKeyCode: destination))
	}

	func removeMapping(_ mapping: KeyMapping) {
		mappings.removeAll { $0.id == mapping.id }
	}

	func resetToDefaults() {
		mappings = KeyMapping.defaultPresets
	}

	// MARK: - Event handling

	private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
		if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
			if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
			return Unmanaged.passUnretained(event)
		}
		guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
			return Unmanaged.passUnretained(event)
		}

		let map = activeMap()
		if map.isEmpty { return Unmanaged.passUnretained(event) }

		let originalKeyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

		// 1) Direct keycode remap (covers normal keys AND modifier key taps like Caps Lock press).
		if let destination = map[originalKeyCode] {
			event.setIntegerValueField(.keyboardEventKeycode, value: Int64(destination))
			// Fix modifier flags: e.g. Control(59) -> Option(58) must swap
			// .maskControl for .maskAlternate so the *modifier meaning* changes too.
			rewriteModifierFlags(event: event, from: originalKeyCode, to: destination)
		}

		// 2) Modifier-chord rewrite: if Control is mapped to Option, then an event
		//    like Ctrl+C arrives with keycode C + .maskControl flag. Rewrite the flag
		//    so the chord behaves as Option+C.
		rewriteChordFlags(event: event, map: map)

		return Unmanaged.passUnretained(event)
	}

	private func rewriteModifierFlags(event: CGEvent, from source: UInt16, to destination: UInt16) {
		event.flags = ModifierFlags.remapped(current: event.flags, from: source, to: destination)
	}

	private func rewriteChordFlags(event: CGEvent, map: [UInt16: UInt16]) {
		event.flags = ModifierFlags.remappedChord(current: event.flags, using: map)
	}
}
