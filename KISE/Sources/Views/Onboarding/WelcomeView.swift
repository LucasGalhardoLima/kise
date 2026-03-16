// KISE/Sources/Views/Onboarding/WelcomeView.swift
import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.xl) {
            Spacer()

            VStack(spacing: KISEDesign.Spacing.md) {
                Text("KISE")
                    .font(KISEDesign.Typography.brand(48))
                    .foregroundStyle(KISEDesign.Colors.textPrimary)

                Text("Dress with intention")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(KISEDesign.Colors.textSecondary)
            }

            Text("KISE learns your wardrobe and suggests outfits based on your style, the weather, and where you're headed.")
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(KISEDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KISEDesign.Spacing.xl)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Get Started")
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
