// KISE/Sources/Views/Suggestion/SuggestionView.swift
import SwiftUI
import SwiftData

struct SuggestionView: View {
    @Environment(ThemeProvider.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SuggestionViewModel()
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var activePieces: [GarmentPiece]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.background.ignoresSafeArea()

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
                    Text("suggestion.title")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(theme.colors.textPrimary)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: String(localized: "suggestion.emptyTitle"),
            message: String(localized: "suggestion.emptyMessage")
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
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Text("\(Int(weather.temperature))°")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("Feels like \(Int(weather.feelsLike))° · Humidity \(Int(weather.humidity))% · Wind \(Int(weather.windSpeed))km/h · \(weather.condition)")
                    .font(KISEDesign.Typography.caption)
                    .foregroundStyle(theme.colors.textTertiary)
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
            .fill(theme.colors.surface)
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                theme.colors.border.opacity(0.3),
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
            Text("suggestion.readyTitle")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            Text("suggestion.readyPieceCount \(activePieces.count)")
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(theme.colors.textSecondary)

            Button {
                Task {
                    await viewModel.fetchSuggestion(context: modelContext)
                }
            } label: {
                Text("suggestion.getSuggestion")
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(theme.colors.background)
                    .padding(.horizontal, KISEDesign.Spacing.xl)
                    .padding(.vertical, KISEDesign.Spacing.md)
                    .background(theme.colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            }
        }
        .containerRelativeFrame(.vertical) { length, _ in length }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Suggestion Content

    private var suggestionContent: some View {
        VStack(spacing: KISEDesign.Spacing.md) {
            // 1. Weather
            weatherSection

            // 2. Occasion pills (context-setter, ABOVE the outfit)
            occasionPills

            // 3. YOUR LOOK + Composition + Piece names
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
                Text("suggestion.yourLook")
                    .kiseSectionLabel()
                outfitCards
            }

            // 4. Reasoning + layering note + alternative swap
            if let suggestion = viewModel.currentSuggestion {
                reasoningSection(suggestion)
            }

            // 5. Boldness slider (thin, inline)
            thinBoldnessSlider

            // 6. Action row (feedback + regenerate, one line)
            actionRow
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
                                ? theme.colors.background
                                : theme.colors.textPrimary
                        )
                        .padding(.horizontal, KISEDesign.Spacing.sm)
                        .padding(.vertical, KISEDesign.Spacing.xs)
                        .background(
                            viewModel.occasion == occasion
                                ? theme.colors.accent
                                : Color.clear
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(theme.colors.accentMuted, lineWidth: viewModel.occasion == occasion ? 0 : 1)
                        )
                }
            }
        }
    }

    // MARK: - Thin Boldness Slider

    private var thinBoldnessSlider: some View {
        HStack(spacing: KISEDesign.Spacing.sm) {
            Text("slider.safe")
                .font(KISEDesign.Typography.small)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(theme.colors.textTertiary)

            GradientTrackSlider(
                value: $viewModel.boldness,
                trackHeight: 3,
                thumbSize: 14,
                onEditingChanged: { editing in
                    if !editing {
                        Task { await viewModel.regenerate(context: modelContext) }
                    }
                }
            )

            Text("slider.bold")
                .font(KISEDesign.Typography.small)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(theme.colors.textTertiary)
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
                .foregroundStyle(theme.colors.textSecondary)

            if let note = suggestion.layeringNote {
                HStack(alignment: .top, spacing: KISEDesign.Spacing.sm) {
                    Image(systemName: "cloud.sun")
                        .font(.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                    Text(note)
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                }
            }

            if let swap = viewModel.alternativeSwap {
                HStack(alignment: .top, spacing: KISEDesign.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                    Text(swap.reason)
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KISEDesign.Spacing.md)
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: KISEDesign.Spacing.lg) {
            Button {
                viewModel.submitFeedback(liked: false, context: modelContext)
            } label: {
                Image(systemName: viewModel.currentSuggestion?.feedback?.liked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.body)
                    .foregroundStyle(
                        viewModel.currentSuggestion?.feedback?.liked == false
                            ? theme.colors.disliked
                            : theme.colors.textTertiary
                    )
            }

            Button {
                Task { await viewModel.regenerate(context: modelContext) }
            } label: {
                HStack(spacing: KISEDesign.Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("suggestion.tryAnother")
                }
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
                .padding(.horizontal, KISEDesign.Spacing.md)
                .padding(.vertical, KISEDesign.Spacing.sm)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.border, lineWidth: 1)
                )
            }

            Button {
                viewModel.submitFeedback(liked: true, context: modelContext)
            } label: {
                Image(systemName: viewModel.currentSuggestion?.feedback?.liked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.body)
                    .foregroundStyle(
                        viewModel.currentSuggestion?.feedback?.liked == true
                            ? theme.colors.liked
                            : theme.colors.textTertiary
                    )
            }
        }
        .padding(.bottom, KISEDesign.Spacing.md)
    }
}

// MARK: - Gradient Track Slider

private struct GradientTrackSlider: View {
    @Environment(ThemeProvider.self) private var theme
    @Binding var value: Double
    var trackHeight: CGFloat = 3
    var thumbSize: CGFloat = 14
    var onEditingChanged: (Bool) -> Void = { _ in }
    @State private var isEditing = false

    var body: some View {
        GeometryReader { geo in
            let usableWidth = geo.size.width - thumbSize
            let thumbX = thumbSize / 2 + usableWidth * value

            ZStack {
                Capsule()
                    .fill(theme.colors.border)
                    .frame(height: trackHeight)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.colors.accentMuted, theme.colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(trackHeight, thumbX), height: trackHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
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
        .frame(height: thumbSize)
    }
}
