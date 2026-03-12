// KISE/Sources/Views/Registration/CategoryPickerView.swift
import SwiftUI

struct CategoryPickerView: View {
    let onSelect: (GarmentCategory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("What type of piece?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                ForEach(GarmentCategory.allCases) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        VStack(spacing: KISEDesign.Spacing.sm) {
                            Image(systemName: category.systemIcon)
                                .font(.system(size: 28))
                                .frame(height: 36)
                            Text(category.displayName)
                                .font(KISEDesign.Typography.caption)
                        }
                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KISEDesign.Spacing.md)
                        .kiseCard()
                    }
                }
            }
        }
    }
}

extension GarmentCategory {
    var systemIcon: String {
        switch self {
        case .tShirt: "tshirt"
        case .shirt: "tshirt"
        case .polo: "tshirt"
        case .sweater: "tshirt"
        case .hoodie: "tshirt"
        case .jacket: "cloud.sun"
        case .coat: "cloud.snow"
        case .jeans: "figure.stand"
        case .chinos: "figure.stand"
        case .shorts: "figure.run"
        case .shoes: "shoe"
        }
    }
}
