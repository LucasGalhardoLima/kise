// KISE/Sources/Views/Wardrobe/GarmentDetailView.swift
import SwiftUI

struct GarmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let piece: GarmentPiece

    var body: some View {
        ScrollView {
            VStack(spacing: KISEDesign.Spacing.lg) {
                // Image
                Group {
                    if let uiImage = CatalogImageService.loadImage(
                        category: piece.category, color: piece.color, fit: piece.fit
                    ) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                            .fill(Color(hex: piece.colorHex).opacity(0.3))
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .overlay {
                                Image(systemName: piece.category.systemIcon)
                                    .font(.system(size: 48))
                                    .foregroundStyle(KISEDesign.Colors.textSecondary)
                            }
                    }
                }
                .frame(maxWidth: 280)
                .kiseCard()

                // Attributes
                VStack(spacing: KISEDesign.Spacing.sm) {
                    attributeRow("Category", piece.category.displayName)
                    attributeRow("Color", piece.color.capitalized)
                    attributeRow("Fit", piece.fit.displayName)
                    attributeRow("Material", piece.material.capitalized)
                    attributeRow("Weight", piece.weight.displayName)
                    attributeRow("Formality", piece.formality.displayName)
                }
                .padding(KISEDesign.Spacing.md)
            }
            .padding(KISEDesign.Spacing.md)
        }
        .background(KISEDesign.Colors.background)
        .navigationTitle(piece.category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(role: piece.isActive ? .destructive : nil) {
                    if piece.isActive {
                        WardrobeViewModel.archivePiece(piece)
                    } else {
                        WardrobeViewModel.restorePiece(piece)
                    }
                    dismiss()
                } label: {
                    Label(
                        piece.isActive ? "Archive" : "Restore",
                        systemImage: piece.isActive ? "archivebox" : "arrow.uturn.backward"
                    )
                    .font(KISEDesign.Typography.bodyText)
                }
            }
        }
    }

    private func attributeRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(KISEDesign.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(KISEDesign.Colors.textPrimary)
        }
        .padding(.vertical, KISEDesign.Spacing.xs)
    }
}
