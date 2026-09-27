import SwiftUI
import AppKit

/// A focusable view that captures the next physical key press and reports its keycode.
/// Used for "press a key" mapping creation.
struct KeyCaptureView: NSViewRepresentable {
    var placeholder: String = "Click here, then press a key…"
    var onCapture: (UInt16) -> Void

    func makeNSView(context: Context) -> CaptureNSView {
        let view = CaptureNSView()
        view.onCapture = onCapture
        return view
    }

    func updateNSView(_ nsView: CaptureNSView, context: Context) {
        nsView.onCapture = onCapture
    }

    final class CaptureNSView: NSView {
        var onCapture: ((UInt16) -> Void)?
        private var label: NSTextField!

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer?.cornerRadius = 6
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.cgColor
            label = NSTextField(labelWithString: "Click here, then press a key…")
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
                widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
                heightAnchor.constraint(equalToConstant: 30),
            ])
        }

        required init?(coder: NSCoder) { fatalError() }

        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            onCapture?(event.keyCode)
            label.stringValue = "\(KeyCode.displayName(for: event.keyCode)) captured ✓ (press another or close)"
        }

        override func flagsChanged(with event: NSEvent) {
            // Capture standalone modifier presses (Shift, Control, Option,
            // Command, Caps Lock, Fn…). NSEvent.keyCode is valid for
            // modifiers in flagsChanged (e.g. Left Command = 55).
            if event.keyCode != 0 || event.modifierFlags.contains(.function) {
                onCapture?(event.keyCode)
                label.stringValue = "\(KeyCode.displayName(for: event.keyCode)) captured ✓"
            }
        }
    }
}
