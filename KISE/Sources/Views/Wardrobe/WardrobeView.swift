// KISE/Sources/Views/Wardrobe/WardrobeView.swift
import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var pieces: [GarmentPiece]

    @State private var viewModel = WardrobeViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: KISEDesign.Spacing.sm) {
                        tabButton("All", tab: nil)
                        ForEach(TabGroup.allCases, id: \.self) { tab in
                            tabButton(tab.rawValue.capitalized, tab: tab)
                        }
                    }
                    .padding(.horizontal, KISEDesign.Spacing.md)
                    .padding(.vertical, KISEDesign.Spacing.sm)
                }

                // Grid or empty state
                if pieces.isEmpty {
                    Spacer()
                    EmptyStateView(
                        title: "Your wardrobe is empty",
                        message: "Add your first pieces to get started",
                        actionLabel: "Add Piece",
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
                            }
                        }
                        .padding(KISEDesign.Spacing.md)
                    }
                }
            }
            .background(KISEDesign.Colors.background)
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
                        ? KISEDesign.Colors.background
                        : KISEDesign.Colors.textPrimary
                )
                .padding(.horizontal, KISEDesign.Spacing.md)
                .padding(.vertical, KISEDesign.Spacing.sm)
                .background(
                    viewModel.selectedTab == tab
                        ? KISEDesign.Colors.accent
                        : KISEDesign.Colors.surface
                )
                .clipShape(Capsule())
        }
    }

    private func garmentCard(_ piece: GarmentPiece) -> some View {
        VStack(spacing: KISEDesign.Spacing.xs) {
            Group {
                if let uiImage = CatalogImageService.loadImage(
                    category: piece.category, color: piece.color, fit: piece.fit
                ) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                        .fill(Color(hex: piece.colorHex).opacity(0.3))
                        .overlay {
                            Image(systemName: piece.category.systemIcon)
                                .foregroundStyle(KISEDesign.Colors.textSecondary)
                        }
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.sm))

            Text("\(piece.color.capitalized) \(piece.category.displayName)")
                .font(KISEDesign.Typography.small)
                .foregroundStyle(KISEDesign.Colors.textSecondary)
                .lineLimit(1)
        }
    }
}
