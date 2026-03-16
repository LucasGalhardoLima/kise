// KISE/Sources/Views/Onboarding/CompositionDemoView.swift
import SwiftUI

struct CompositionDemoView: View {
    let onContinue: () -> Void

    /// Hardcoded sample pieces for the demo composition (spec: 3 pieces, varied colors)
    private let samplePieces: [GarmentPiece] = {
        let polo = GarmentPiece(category: .polo, color: "lightBlue", colorHex: "#A4C8E8",
                                fit: .regular, material: "cotton", weight: .mid, formality: .casual)
        let chinos = GarmentPiece(category: .chinos, color: "sage", colorHex: "#9CAF88",
                                  fit: .regular, material: "cotton", weight: .mid, formality: .casual)
        let shoes = GarmentPiece(category: .shoes, color: "black", colorHex: "#2C2C2C",
                                 fit: .regular, material: "leather", weight: .mid, formality: .casual)
        return [polo, chinos, shoes]
    }()

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.xl) {
            Spacer()

            VStack(spacing: KISEDesign.Spacing.md) {
                Text("Your outfit, as color")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(KISEDesign.Colors.textPrimary)

                Text("KISE shows your outfit as a color composition — tap to explore how pieces work together.")
                    .font(KISEDesign.Typography.bodyText)
                    .foregroundStyle(KISEDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KISEDesign.Spacing.md)
            }

            // Reuse real ColorCompositionView per spec
            ColorCompositionView(pieces: samplePieces)
                .padding(.horizontal, KISEDesign.Spacing.xl)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(KISEDesign.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KISEDesign.Spacing.md)
                    .background(KISEDesign.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            }
            .padding(.horizontal, KISEDesign.Spacing.md)
            .padding(.bottom, KISEDesign.Spacing.lg)
        }
        .background(KISEDesign.Colors.background)
    }
}
