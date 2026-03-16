// KISE/Sources/Views/Onboarding/OnboardingFlowView.swift
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(ThemeProvider.self) private var theme
    @State private var currentPage = 0
    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: KISEDesign.Spacing.sm) {
                ForEach(0..<totalPages, id: \.self) { page in
                    Circle()
                        .fill(page == currentPage ? theme.colors.accent : theme.colors.border)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, KISEDesign.Spacing.lg)

            // Pages
            TabView(selection: $currentPage) {
                WelcomeView {
                    withAnimation { currentPage = 1 }
                }
                .tag(0)

                CompositionDemoView {
                    withAnimation { currentPage = 2 }
                }
                .tag(1)

                LocationPermissionView {
                    withAnimation { currentPage = 3 }
                }
                .tag(2)

                StyleOnboardingView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
        .background(theme.colors.background)
    }
}
