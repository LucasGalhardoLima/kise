// KISE/Sources/Views/Suggestion/SuggestionView.swift
import SwiftUI
import SwiftData

struct SuggestionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SuggestionViewModel()
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var activePieces: [GarmentPiece]

    var body: some View {
        NavigationStack {
            ZStack {
                KISEDesign.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: KISEDesign.Spacing.lg) {
                        if activePieces.count < 2 {
                            emptyState
                        } else if viewModel.isLoading && viewModel.currentSuggestion == nil {
                            loadingState
                        } else if viewModel.currentSuggestion != nil {
                            suggestionContent
                                .opacity(viewModel.isRegenerating ? 0.5 : 1.0)
                                .allowsHitTesting(!viewModel.isRegenerating)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.isRegenerating)
                        } else {
                            readyState
                        }
                    }
                    .padding(.horizontal, KISEDesign.Spacing.md)
                    .padding(.top, KISEDesign.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await viewModel.fetchWeather()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Today")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: "Build your wardrobe",
            message: "Add at least 2 pieces and I'll start suggesting outfits."
        )
        .containerRelativeFrame(.vertical) { length, _ in length }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weather

    @ViewBuilder
    private var weatherSection: some View {
        if let weather = viewModel.weather {
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.xs) {
                if let city = viewModel.cityName {
                    Text(city)
                        .font(KISEDesign.Typography.bodyText)
                        .foregroundStyle(KISEDesign.Colors.textSecondary)
                }
                Text("\(Int(weather.temperature))°")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(KISEDesign.Colors.textPrimary)
                Text("Feels like \(Int(weather.feelsLike))° · Humidity \(Int(weather.humidity))% · Wind \(Int(weather.windSpeed))km/h · \(weather.condition)")
                    .font(KISEDesign.Typography.caption)
                    .foregroundStyle(KISEDesign.Colors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: KISEDesign.Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                skeletonCard
            }
        }
        .padding(.top, KISEDesign.Spacing.md)
    }

    private var skeletonCard: some View {
        RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
            .fill(KISEDesign.Colors.surface)
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                KISEDesign.Colors.border.opacity(0.3),
                                Color.clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .phaseAnimator([false, true]) { content, phase in
                        content.offset(x: phase ? 200 : -200)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            .kiseCard()
    }

    // MARK: - Ready State (has pieces, no suggestion yet)

    private var readyState: some View {
        VStack(spacing: KISEDesign.Spacing.lg) {
            Spacer().frame(height: KISEDesign.Spacing.xxl)

            Text("Ready when you are")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            Text("\(activePieces.count) pieces in your wardrobe")
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(KISEDesign.Colors.textSecondary)

            Button {
                Task {
                    await viewModel.fetchSuggestion(context: modelContext)
                }
            } label: {
                Text("Get a suggestion")
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(KISEDesign.Colors.background)
                    .padding(.horizontal, KISEDesign.Spacing.xl)
                    .padding(.vertical, KISEDesign.Spacing.md)
                    .background(KISEDesign.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            }
        }
    }

    // MARK: - Suggestion Content

    private var suggestionContent: some View {
        VStack(spacing: KISEDesign.Spacing.lg) {
            // 1. Weather
            weatherSection

            // 2. Your Look + Composition
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
                Text("Your Look")
                    .kiseSectionLabel()
                outfitCards
            }

            // 3. Reasoning
            if let suggestion = viewModel.currentSuggestion {
                reasoningSection(suggestion)
            }

            // 4. Feedback
            feedbackButtons

            // 5. Occasion pills (always visible)
            occasionPills

            // 6. Boldness slider (always visible, gradient)
            gradientBoldnessSlider

            // 7. Try another
            regenerateButton
        }
    }

    // MARK: - Occasion Pills

    private var occasionPills: some View {
        HStack(spacing: KISEDesign.Spacing.sm) {
            ForEach(Occasion.allCases) { occasion in
                Button {
                    viewModel.occasion = occasion
                    Task { await viewModel.regenerate(context: modelContext) }
                } label: {
                    Text(occasion.displayName)
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(
                            viewModel.occasion == occasion
                                ? KISEDesign.Colors.background
                                : KISEDesign.Colors.textPrimary
                        )
                        .padding(.horizontal, KISEDesign.Spacing.sm)
                        .padding(.vertical, KISEDesign.Spacing.xs)
                        .background(
                            viewModel.occasion == occasion
                                ? KISEDesign.Colors.accent
                                : KISEDesign.Colors.surface
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(KISEDesign.Colors.accentMuted, lineWidth: viewModel.occasion == occasion ? 0 : 1)
                        )
                }
            }
        }
    }

    // MARK: - Gradient Boldness Slider

    private var gradientBoldnessSlider: some View {
        VStack(spacing: KISEDesign.Spacing.xs) {
            HStack {
                Text("Safe")
                    .font(KISEDesign.Typography.small)
                    .foregroundStyle(KISEDesign.Colors.textTertiary)
                Spacer()
                Text("Bold")
                    .font(KISEDesign.Typography.small)
                    .foregroundStyle(KISEDesign.Colors.textTertiary)
            }

            GradientTrackSlider(
                value: $viewModel.boldness,
                onEditingChanged: { editing in
                    if !editing {
                        Task { await viewModel.regenerate(context: modelContext) }
                    }
                }
            )
        }
    }

    // MARK: - Outfit Cards

    private var outfitCards: some View {
        ColorCompositionView(
            pieces: viewModel.suggestedPieces,
            swappablePieceID: viewModel.alternativeSwap?.swapPieceID,
            onSwap: {
                withAnimation { viewModel.applyAlternative() }
            }
        )
    }

    // MARK: - Reasoning

    private func reasoningSection(_ suggestion: OutfitSuggestion) -> some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
            Text(suggestion.reasoning)
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(KISEDesign.Colors.textSecondary)

            if let note = suggestion.layeringNote {
                HStack(alignment: .top, spacing: KISEDesign.Spacing.sm) {
                    Image(systemName: "cloud.sun")
                        .font(.caption)
                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                    Text(note)
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                }
            }

            if let swap = viewModel.alternativeSwap {
                HStack(alignment: .top, spacing: KISEDesign.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                    Text(swap.reason)
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KISEDesign.Spacing.md)
    }

    // MARK: - Feedback

    private var feedbackButtons: some View {
        HStack(spacing: KISEDesign.Spacing.xl) {
            Button {
                viewModel.submitFeedback(liked: false, context: modelContext)
            } label: {
                Image(systemName: viewModel.currentSuggestion?.feedback?.liked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.currentSuggestion?.feedback?.liked == false
                            ? KISEDesign.Colors.disliked
                            : KISEDesign.Colors.textTertiary
                    )
            }

            Button {
                viewModel.submitFeedback(liked: true, context: modelContext)
            } label: {
                Image(systemName: viewModel.currentSuggestion?.feedback?.liked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.currentSuggestion?.feedback?.liked == true
                            ? KISEDesign.Colors.liked
                            : KISEDesign.Colors.textTertiary
                    )
            }
        }
        .padding(.vertical, KISEDesign.Spacing.sm)
    }

    // MARK: - Regenerate

    private var regenerateButton: some View {
        Button {
            Task {
                await viewModel.regenerate(context: modelContext)
            }
        } label: {
            HStack(spacing: KISEDesign.Spacing.sm) {
                Image(systemName: "arrow.clockwise")
                Text("Try another")
            }
            .font(KISEDesign.Typography.caption)
            .foregroundStyle(KISEDesign.Colors.textSecondary)
            .padding(.horizontal, KISEDesign.Spacing.md)
            .padding(.vertical, KISEDesign.Spacing.sm)
            .overlay(
                Capsule()
                    .strokeBorder(KISEDesign.Colors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, KISEDesign.Spacing.lg)
    }
}

// MARK: - Gradient Track Slider

private struct GradientTrackSlider: View {
    @Binding var value: Double
    var onEditingChanged: (Bool) -> Void = { _ in }
    @State private var isEditing = false

    var body: some View {
        GeometryReader { geo in
            let thumbSize: CGFloat = 24
            let trackHeight: CGFloat = 4
            let usableWidth = geo.size.width - thumbSize
            let thumbX = thumbSize / 2 + usableWidth * value

            ZStack {
                // Background track
                Capsule()
                    .fill(KISEDesign.Colors.border)
                    .frame(height: trackHeight)

                // Gradient fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [KISEDesign.Colors.accentMuted, KISEDesign.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(trackHeight, thumbX), height: trackHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Thumb
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .frame(width: thumbSize, height: thumbSize)
                    .position(x: thumbX, y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isEditing {
                            isEditing = true
                            onEditingChanged(true)
                        }
                        let raw = (drag.location.x - thumbSize / 2) / usableWidth
                        let clamped = min(max(raw, 0), 1)
                        let stepped = (clamped * 10).rounded() / 10
                        if stepped != value {
                            value = stepped
                        }
                    }
                    .onEnded { _ in
                        isEditing = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 24)
    }
}
