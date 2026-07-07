//
//  HotkeyMonitor.swift
//  App-local keyboard monitor for pad hotkeys. A local NSEvent monitor needs
//  no Accessibility permission and fires regardless of SwiftUI focus.
//

import AppKit

@MainActor
final class HotkeyMonitor {
    private var monitor: Any?

    /// Start monitoring. `handler` receives a single lowercase character and
    /// returns true if it handled the key (the event is then swallowed).
    func start(handler: @escaping @MainActor (String) -> Bool) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Local monitors are always invoked on the main thread.
            MainActor.assumeIsolated {
                // Don't steal keystrokes while the user is typing in a text
                // field (the field editor is an NSTextView).
                if NSApp.keyWindow?.firstResponder is NSTextView { return event }
                guard event.modifierFlags.intersection([.command, .option, .control]).isEmpty,
                      let key = event.charactersIgnoringModifiers?.lowercased(),
                      key.count == 1
                else { return event }
                return handler(key) ? nil : event
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

/// App-lifetime owner of the hotkey monitor. Lives at the App level so
/// hotkeys keep working whichever windows are open or closed.
@MainActor
final class HotkeyController: ObservableObject {
    private let monitor = HotkeyMonitor()

    init(bankStore: BankStore, playbackEngine: PlaybackEngine) {
        monitor.start { [weak bankStore, weak playbackEngine] key in
            guard let item = bankStore?.item(withHotkey: key) else { return false }
            playbackEngine?.toggle(item: item)
            return true
        }
    }
}
