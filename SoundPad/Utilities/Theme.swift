//
//  Theme.swift
//  Shared colors for the dark, studio-style look.
//

import SwiftUI

enum Theme {
    /// Window background.
    static let background = LinearGradient(
        colors: [
            Color(red: 0.09, green: 0.10, blue: 0.13),
            Color(red: 0.13, green: 0.14, blue: 0.19),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Pad / mixer-row card fill.
    static let card = LinearGradient(
        colors: [
            Color(red: 0.19, green: 0.20, blue: 0.26),
            Color(red: 0.14, green: 0.15, blue: 0.20),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBorder = Color.white.opacity(0.08)
    static let cardBorderHover = Color.white.opacity(0.25)
    static let textSecondary = Color.white.opacity(0.55)
    static let controlFill = Color.white.opacity(0.08)

    static let defaultHighlightHex = "#FFD700"

    static func highlight(fromHex hex: String) -> Color {
        Color(hex: hex) ?? Color(hex: defaultHighlightHex) ?? .yellow
    }
}
