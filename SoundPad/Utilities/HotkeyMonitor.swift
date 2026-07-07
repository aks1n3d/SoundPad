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
    func start(handler: @escaping (String) -> Bool) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Don't steal keystrokes while the user is typing in a text field
            // (the field editor is an NSTextView).
            if NSApp.keyWindow?.firstResponder is NSTextView { return event }
            guard event.modifierFlags.intersection([.command, .option, .control]).isEmpty,
                  let key = event.charactersIgnoringModifiers?.lowercased(),
                  key.count == 1
            else { return event }
            return handler(key) ? nil : event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
