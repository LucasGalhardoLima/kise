// KISE/Sources/Views/Onboarding/LocationPermissionView.swift
import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @Environment(ThemeProvider.self) private var theme
    let onContinue: () -> Void
    @State private var locationManager = CLLocationManager()

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.xl) {
            Spacer()

            VStack(spacing: KISEDesign.Spacing.md) {
                Image(systemName: "location.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(theme.colors.accent)

                Text("onboarding.locationTitle")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("onboarding.locationDescription")
                    .font(KISEDesign.Typography.bodyText)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KISEDesign.Spacing.md)
            }

            Spacer()

            VStack(spacing: KISEDesign.Spacing.sm) {
                Button {
                    locationManager.requestWhenInUseAuthorization()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onContinue()
                    }
                } label: {
                    Text("onboarding.allowLocation")
                        .font(KISEDesign.Typography.subtitle)
                        .foregroundStyle(theme.colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KISEDesign.Spacing.md)
                        .background(theme.colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
                }

                Button {
                    onContinue()
                } label: {
                    Text("action.skip")
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                }
            }
            .padding(.horizontal, KISEDesign.Spacing.md)
            .padding(.bottom, KISEDesign.Spacing.lg)
        }
        .background(theme.colors.background)
    }
}
