//
//  ColorHex.swift
//  Converts between "#RRGGBB" strings (stored in @AppStorage) and SwiftUI Color.
//

import SwiftUI

extension Color {
    /// Parse "#RRGGBB" (leading "#" optional). Returns nil for anything else.
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    /// "#RRGGBB" representation (alpha discarded).
    var hexString: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(srgbRed: 1, green: 0.84, blue: 0, alpha: 1)
        let r = Int(round(ns.redComponent * 255))
        let g = Int(round(ns.greenComponent * 255))
        let b = Int(round(ns.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
