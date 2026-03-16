// KISE/Sources/Views/Onboarding/StyleOnboardingView.swift
import SwiftUI

struct StyleOnboardingView: View {
    @Environment(ThemeProvider.self) private var theme
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: KISEDesign.Spacing.sm) {
                Text("KISE")
                    .font(KISEDesign.Typography.largeTitle)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("Select the styles that inspire you")
                    .font(KISEDesign.Typography.bodyText)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.top, KISEDesign.Spacing.xxl)
            .padding(.bottom, KISEDesign.Spacing.lg)

            // Archetype Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                    ForEach(StyleArchetype.allCases) { archetype in
                        ArchetypeCard(
                            archetype: archetype,
                            isSelected: viewModel.isSelected(archetype)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleArchetype(archetype)
                            }
                        }
                    }
                }
                .padding(.horizontal, KISEDesign.Spacing.md)
            }

            // Continue Button
            Button {
                viewModel.saveProfile(context: modelContext)
                appState.completeOnboarding()
            } label: {
                Text("Continue")
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(theme.colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KISEDesign.Spacing.md)
                    .background(
                        viewModel.canContinue
                            ? theme.colors.accent
                            : theme.colors.textTertiary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            }
            .disabled(!viewModel.canContinue)
            .padding(KISEDesign.Spacing.md)
        }
        .background(theme.colors.background)
    }
}

// MARK: - Archetype Card

private struct ArchetypeCard: View {
    @Environment(ThemeProvider.self) private var theme
    let archetype: StyleArchetype
    let isSelected: Bool

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.sm) {
            // Moodboard image — loads from asset catalog, falls back to styled placeholder
            ZStack {
                RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                    .fill(theme.colors.border.opacity(0.5))

                if let uiImage = UIImage(named: archetype.assetKey) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    // Styled placeholder until real moodboard images are added
                    VStack(spacing: KISEDesign.Spacing.xs) {
                        Image(systemName: archetype.placeholderIcon)
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.sm))

            Text(archetype.displayName)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .padding(KISEDesign.Spacing.sm)
        .background(isSelected ? theme.colors.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
        .overlay {
            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                .stroke(
                    isSelected ? theme.colors.accentMuted : Color.clear,
                    lineWidth: 2
                )
        }
    }
}
