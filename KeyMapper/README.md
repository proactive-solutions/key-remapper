# KeyMapper — macOS SwiftUI Key Remapper

Background, menu-bar key remapping app for macOS. System-wide remapping via `CGEventTap`, launch-at-login via `SMAppService`, no Dock icon (`LSUIElement`).

## Features

- **System-wide remapping**: any `S` press behaves as `Z`, `Control` behaves as `Option (Alt)`, `Caps Lock` acts as another key, function keys (F1–F20) emit alphanumeric keys, etc.
- **Modifier-aware**: maps both the key tap *and* the modifier flag, so `Ctrl+C` becomes `Alt+C` when Control → Option is enabled. Handles `flagsChanged` events (required for Caps Lock / Shift / Control / Option / Command / Fn).
- **Menu-bar background app**: no Dock icon, lives in the menu bar with Start/Pause, Settings, Quit.
- **Launch at boot**: Settings toggle registers `SMAppService.mainApp` login item (macOS 13+).
- **Press-to-capture**: "Press FROM/TO key…" buttons capture physical keycodes, including standalone modifiers.
- **Persistent**: mappings stored as JSON in `UserDefaults`, with example presets on first launch.

Default presets (edit/delete in Settings):

| From | To |
|------|----|
| S (1) | Z (6) |
| Left Control (59) | Left Option / Alt (58) |
| Caps Lock (57) | Escape (53) |
| F1 (122) | A (0) |

## Project layout

```
KeyMapper.xcodeproj
KeyMapper/
  KeyMapperApp.swift          # @main App, MenuBarExtra + Settings scene, auto-start
  Models/KeyMapping.swift     # KeyMapping model + full virtual-keycode table
  Services/KeyRemapper.swift  # CGEventTap engine (keyDown/keyUp/flagsChanged)
  Services/PermissionsManager.swift
  Services/LaunchAtLoginManager.swift  # SMAppService wrapper
  Views/SettingsView.swift    # mapping list, pickers, permissions UI
  Views/KeyCaptureView.swift  # NSViewRepresentable key press capture
  Info.plist                  # LSUIElement=true (background, no Dock)
```

## Requirements

- macOS 14+, Xcode 16+, Swift 5
- **Accessibility permission** (mandatory): System Settings → Privacy & Security → Accessibility → enable KeyMapper. On some macOS versions also allow Input Monitoring.
- No sandbox (`ENABLE_APP_SANDBOX = NO`) — event taps do not work sandboxed.
- Ad-hoc signing is enough for local use (`CODE_SIGN_IDENTITY="-"`).

## Build & run

```bash
xcodebuild -project KeyMapper.xcodeproj -scheme KeyMapper -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES
open ~/Library/Developer/Xcode/DerivedData/Build/Products/Debug/KeyMapper.app
```

Or open `KeyMapper.xcodeproj` in Xcode and press Run. Change the bundle ID (`com.local.KeyMapper`) and add your development team for your own signing / login-item testing.

First run:
1. Open Settings from the menu-bar icon (⌨️).
2. Grant Accessibility when prompted, then toggle **Enabled** off/on.
3. Toggle **Launch at login** to auto-start after boot.
4. Add/edit mappings; changes apply live on the next key event (no tap restart needed).

## How it works

- `KeyRemapper.start()` creates a `.cgSessionEventTap` with `.headInsertEventTap` for `keyDown | keyUp | flagsChanged` and runs it on a dedicated high-priority thread (`CFRunLoopRun`).
- Callback rewrites `kCGKeyboardEventKeycode` and swaps `CGEventFlags` (e.g. `.maskControl` ↔ `.maskAlternate`) so modifiers change meaning both alone and in chords.
- `tapDisabledByTimeout / tapDisabledByUserInput` re-enables the tap.
- `LaunchAtLoginManager` wraps `SMAppService.mainApp.register()/unregister()`.

## Limitations & notes

- Caps Lock has OS-level special handling (LED, delay). Remapping Caps → Escape/Ctrl works for most apps but may feel slightly different from native System Settings modifier remap. For pure modifier swaps, System Settings → Keyboard → Modifier Keys is lower latency.
- Secure Input (password fields), FileVault login screen, and elevated UIs may not deliver events to the tap.
- Function/media keys that arrive as `NSSystemDefined` rather than key events may not remap; standard F1–F12 in function mode do.
- Login-item registration works best with a properly signed, non-ad-hoc build placed in `/Applications`.
