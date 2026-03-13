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

            VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
                ForEach(TabGroup.allCases, id: \.self) { group in
                    let categories = GarmentCategory.allCases.filter { $0.tabGroup == group }
                    VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
                        Text(group.rawValue.capitalized)
                            .kiseSectionLabel()

                        LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                            ForEach(categories) { category in
                                Button {
                                    onSelect(category)
                                } label: {
                                    Text(category.displayName)
                                        .font(KISEDesign.Typography.caption)
                                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, KISEDesign.Spacing.md)
                                        .kiseCard()
                                        .overlay {
                                            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                                .strokeBorder(KISEDesign.Colors.accentMuted, lineWidth: 1)
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
