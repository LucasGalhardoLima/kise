// KISE/Sources/Views/Registration/CatalogConfirmView.swift
import SwiftUI

struct CatalogConfirmView: View {
    let imageKey: String?
    let category: GarmentCategory
    let color: GarmentColor
    let fit: Fit
    let onConfirm: () -> Void
    let onTakePhoto: () -> Void

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.lg) {
            Text("Does this look like your piece?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            // Catalog image or placeholder
            Group {
                if let imageKey, let uiImage = UIImage(named: imageKey) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    // Placeholder when no catalog image exists
                    RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                        .fill(color.color.opacity(0.3))
                        .overlay {
                            VStack(spacing: KISEDesign.Spacing.sm) {
                                Image(systemName: category.systemIcon)
                                    .font(.system(size: 48))
                                Text("\(color.name) \(category.displayName)")
                                    .font(KISEDesign.Typography.caption)
                            }
                            .foregroundStyle(KISEDesign.Colors.textSecondary)
                        }
                }
            }
            .frame(maxWidth: 280, maxHeight: 360)
            .kiseCard()

            VStack(spacing: KISEDesign.Spacing.sm) {
                Button {
                    onConfirm()
                } label: {
                    Text("Yes, that's it")
                        .font(KISEDesign.Typography.subtitle)
                        .foregroundStyle(KISEDesign.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KISEDesign.Spacing.md)
                        .background(KISEDesign.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
                }

                Button {
                    onTakePhoto()
                } label: {
                    Text("Not quite — I'll take a photo")
                        .font(KISEDesign.Typography.bodyText)
                        .foregroundStyle(KISEDesign.Colors.textSecondary)
                }
            }
        }
    }
}
