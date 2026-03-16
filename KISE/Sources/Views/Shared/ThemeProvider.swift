// KISE/Sources/Views/Shared/ThemeProvider.swift
import SwiftUI

@Observable
final class ThemeProvider {
    var colors: ThemeColors

    init(theme: ThemeColors = .default) {
        self.colors = theme
    }
}

struct ThemeColors {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color
    let accentSecondary: Color
    let accentMuted: Color
    let border: Color
    let cardShadow: Color
    let liked: Color
    let disliked: Color

    static let `default` = ThemeColors(
        background: Color(hex: "#F5F3EF"),
        surface: .white,
        textPrimary: Color(hex: "#344E41"),
        textSecondary: Color(hex: "#6B6B6B"),
        textTertiary: Color(hex: "#9B9B9B"),
        accent: Color(hex: "#3A5A40"),
        accentSecondary: Color(hex: "#588157"),
        accentMuted: Color(hex: "#A3B18A"),
        border: Color(hex: "#E5E1DB"),
        cardShadow: .black.opacity(0.06),
        liked: Color(hex: "#588157"),
        disliked: Color(hex: "#8B4B4B")
    )
}
