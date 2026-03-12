// KISE/Sources/Views/Shared/DesignSystem.swift
import SwiftUI

enum KISEDesign {

    // MARK: - Colors

    enum Colors {
        static let background = Color(hex: "#F5F3EF")
        static let surface = Color.white
        static let textPrimary = Color(hex: "#1A1A1A")
        static let textSecondary = Color(hex: "#6B6B6B")
        static let textTertiary = Color(hex: "#9B9B9B")
        static let accent = Color(hex: "#1A1A1A")
        static let border = Color(hex: "#E5E1DB")
        static let cardShadow = Color.black.opacity(0.06)
        static let liked = Color(hex: "#4A7C59")
        static let disliked = Color(hex: "#8B4B4B")
    }

    // MARK: - Typography
    // Two layers: DM Sans (interface) + Cormorant Garamond (brand identity)

    enum Typography {
        // Interface font: DM Sans (bundled)
        static let interfaceFont = "DMSans-Regular"
        static let interfaceFontLight = "DMSans-Light"
        static let interfaceFontMedium = "DMSans-Medium"

        // Brand font: Cormorant Garamond (splash/wordmark only)
        static let brandFont = "CormorantGaramond-Light"

        static func heading(_ size: CGFloat) -> Font {
            .custom(interfaceFontLight, size: size)
        }

        static func headingMedium(_ size: CGFloat) -> Font {
            .custom(interfaceFontMedium, size: size)
        }

        static func body(_ size: CGFloat) -> Font {
            .custom(interfaceFont, size: size)
        }

        static func bodyMedium(_ size: CGFloat) -> Font {
            .custom(interfaceFontMedium, size: size)
        }

        /// Brand wordmark font — only for "KISE 着せ" signature
        static func brand(_ size: CGFloat) -> Font {
            .custom(brandFont, size: size)
        }

        // Predefined sizes
        static let largeTitle = heading(32)
        static let title = heading(24)
        static let subtitle = bodyMedium(17)
        static let bodyText = body(15)
        static let caption = body(13)
        static let small = body(11)
        static let brandTitle = brand(36)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }
}

// MARK: - Card Style Modifier

struct KISECardStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: KISEDesign.Radius.md))
        } else {
            content
                .background(KISEDesign.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
                .shadow(color: KISEDesign.Colors.cardShadow, radius: 8, x: 0, y: 2)
        }
    }
}

extension View {
    func kiseCard() -> some View {
        modifier(KISECardStyle())
    }
}
