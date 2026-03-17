// KISE/Sources/Views/Onboarding/CompositionDemoView.swift
import SwiftUI

struct CompositionDemoView: View {
    @Environment(ThemeProvider.self) private var theme
    let onContinue: () -> Void
    @State private var currentPreset = 0

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.xl) {
            Spacer()

            VStack(spacing: KISEDesign.Spacing.md) {
                Text("onboarding.demoTitle")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("onboarding.demoDescription")
                    .font(KISEDesign.Typography.bodyText)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KISEDesign.Spacing.md)
            }

            // Composition preview
            ColorCompositionView(pieces: Self.presetOutfits[currentPreset])
                .padding(.horizontal, KISEDesign.Spacing.xl)
                .id(currentPreset)
                .transition(.opacity)

            // Generate button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPreset = (currentPreset + 1) % Self.presetOutfits.count
                }
            } label: {
                HStack(spacing: KISEDesign.Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("onboarding.generate")
                }
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, KISEDesign.Spacing.md)
                .padding(.vertical, KISEDesign.Spacing.sm)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.accentMuted, lineWidth: 1)
                )
            }

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("action.continue")
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(theme.colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KISEDesign.Spacing.md)
                    .background(theme.colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            }
            .padding(.horizontal, KISEDesign.Spacing.md)
            .padding(.bottom, KISEDesign.Spacing.lg)
        }
        .background(theme.colors.background)
    }

    // MARK: - Preset Outfits

    static let presetOutfits: [[GarmentPiece]] = [
        makePieces((.polo, "navy", "#1B2A4A"), (.chinos, "beige", "#D4C5A9"), (.shoes, "brown", "#6B4226")),
        makePieces((.sweater, "camel", "#C19A6B"), (.jeans, "indigo", "#3F5277"), (.shoes, "black", "#1A1A1A")),
        makePieces((.tShirt, "white", "#FFFFFF"), (.shorts, "olive", "#6B7F4E"), (.shoes, "tan", "#C2956B")),
        makePieces((.shirt, "lightBlue", "#A4C8E8"), (.chinos, "charcoal", "#4A4A4A"), (.shoes, "burgundy", "#722F37")),
        makePieces((.sweater, "sage", "#9CAF88"), (.jeans, "black", "#1A1A1A"), (.shoes, "white", "#FFFFFF")),
        makePieces((.polo, "terracotta", "#C75B39"), (.chinos, "cream", "#F5F0E8"), (.shoes, "brown", "#6B4226")),
        makePieces((.tShirt, "lightGray", "#C8C8C8"), (.chinos, "navy", "#1B2A4A"), (.shoes, "white", "#FFFFFF")),
        makePieces((.shirt, "mustard", "#D4A520"), (.jeans, "charcoal", "#4A4A4A"), (.shoes, "black", "#1A1A1A")),
        makePieces((.jacket, "khaki", "#C4A46C"), (.tShirt, "white", "#FFFFFF"), (.jeans, "indigo", "#3F5277")),
        makePieces((.shirt, "black", "#1A1A1A"), (.chinos, "charcoal", "#4A4A4A"), (.shoes, "maroon", "#5B1E31")),
    ]

    private static func makePieces(_ items: (GarmentCategory, String, String)...) -> [GarmentPiece] {
        items.map { category, color, hex in
            GarmentPiece(category: category, color: color, colorHex: hex,
                         fit: .regular, material: "cotton", weight: .mid, formality: .casual)
        }
    }
}
