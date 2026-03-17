// KISE/Sources/Views/Wardrobe/WardrobeView.swift
import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(ThemeProvider.self) private var theme
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var pieces: [GarmentPiece]

    @Query(sort: \OutfitSuggestion.suggestedAt, order: .reverse)
    private var suggestions: [OutfitSuggestion]

    @State private var viewModel = WardrobeViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats row
                if !pieces.isEmpty {
                    StatsRowView(items: [
                        StatItem(count: viewModel.inRotationCount, label: String(localized: "stats.inRotation")),
                        StatItem(count: viewModel.rarelyUsedCount, label: String(localized: "stats.rarelyUsed"),
                                 action: { viewModel.showDormantPieces = true }),
                        StatItem(count: viewModel.dormantCount, label: String(localized: "stats.dormant"),
                                 action: { viewModel.showDormantPieces = true }),
                    ])
                    .padding(.horizontal, KISEDesign.Spacing.md)
                }

                // Tab filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: KISEDesign.Spacing.sm) {
                        tabButton(String(localized: "wardrobe.tabAll") + " \(pieces.count)", tab: nil)
                        ForEach(TabGroup.allCases, id: \.self) { tab in
                            let count = pieces.filter { $0.category.tabGroup == tab }.count
                            tabButton("\(tab.displayName) \(count)", tab: tab)
                        }
                    }
                    .padding(.horizontal, KISEDesign.Spacing.md)
                    .padding(.vertical, KISEDesign.Spacing.sm)
                }

                // Grid or empty state
                if pieces.isEmpty {
                    Spacer()
                    EmptyStateView(
                        title: String(localized: "wardrobe.emptyTitle"),
                        message: String(localized: "wardrobe.emptyMessage"),
                        actionLabel: String(localized: "wardrobe.addPiece"),
                        action: { viewModel.showRegistration = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                            ForEach(viewModel.filterPieces(pieces)) { piece in
                                Button {
                                    viewModel.selectedPiece = piece
                                } label: {
                                    garmentCard(piece)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            WardrobeViewModel.archivePiece(piece)
                                        }
                                    } label: {
                                        Label(String(localized: "action.archive"), systemImage: "archivebox")
                                    }
                                }
                            }
                        }
                        .padding(KISEDesign.Spacing.md)
                    }
                }
            }
            .background {
                theme.colors.background.ignoresSafeArea()
            }
            .navigationDestination(isPresented: $viewModel.showDormantPieces) {
                DormantPiecesView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("wardrobe.title")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(theme.colors.textPrimary)
                }
            }
            .sheet(isPresented: $viewModel.showRegistration) {
                RegistrationFlowView()
            }
            .sheet(item: $viewModel.selectedPiece) { piece in
                NavigationStack {
                    GarmentDetailView(piece: piece)
                }
            }
            .onAppear {
                viewModel.computeStats(pieces: pieces, suggestions: suggestions)
            }
            .onChange(of: pieces.count) {
                viewModel.computeStats(pieces: pieces, suggestions: suggestions)
            }
            .onChange(of: suggestions.count) {
                viewModel.computeStats(pieces: pieces, suggestions: suggestions)
            }
        }
    }

    private func tabButton(_ label: String, tab: TabGroup?) -> some View {
        Button {
            withAnimation { viewModel.selectedTab = tab }
        } label: {
            Text(label)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(
                    viewModel.selectedTab == tab
                        ? theme.colors.background
                        : theme.colors.textPrimary
                )
                .padding(.horizontal, KISEDesign.Spacing.md)
                .padding(.vertical, KISEDesign.Spacing.sm)
                .background(
                    viewModel.selectedTab == tab
                        ? theme.colors.accent
                        : theme.colors.surface
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            viewModel.selectedTab == tab
                                ? Color.clear
                                : theme.colors.accentMuted,
                            lineWidth: 1
                        )
                )
        }
    }

    private func garmentCard(_ piece: GarmentPiece) -> some View {
        ColorTileView(
            colorHex: piece.colorHex,
            colorName: piece.color,
            colorDisplayName: piece.colorDisplayName,
            category: piece.category.displayName,
            material: piece.material,
            lastUsedText: viewModel.lastUsedText(for: piece.id),
            daysUnused: viewModel.daysUnused(for: piece)
        )
    }
}
