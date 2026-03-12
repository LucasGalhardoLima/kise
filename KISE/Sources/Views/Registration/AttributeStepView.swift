// KISE/Sources/Views/Registration/AttributeStepView.swift
import SwiftUI

// MARK: - Color Picker Step

struct ColorPickerStepView: View {
    let onSelect: (GarmentColor) -> Void

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("What color?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                ForEach(GarmentColor.allColors) { color in
                    Button {
                        onSelect(color)
                    } label: {
                        VStack(spacing: KISEDesign.Spacing.xs) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Circle().stroke(KISEDesign.Colors.border, lineWidth: 1)
                                }
                            Text(color.name)
                                .font(KISEDesign.Typography.small)
                                .foregroundStyle(KISEDesign.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Generic Option Picker Step

struct OptionPickerStepView<T: Identifiable>: View where T: Equatable {
    let title: String
    let options: [T]
    let labelFor: (T) -> String
    let suggested: T?
    let onSelect: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text(title)
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            VStack(spacing: KISEDesign.Spacing.sm) {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        HStack {
                            Text(labelFor(option))
                                .font(KISEDesign.Typography.bodyText)
                                .foregroundStyle(KISEDesign.Colors.textPrimary)

                            Spacer()

                            if let suggested, suggested.id as AnyHashable == option.id as AnyHashable {
                                Text("Suggested")
                                    .font(KISEDesign.Typography.small)
                                    .foregroundStyle(KISEDesign.Colors.textTertiary)
                            }
                        }
                        .padding(KISEDesign.Spacing.md)
                        .kiseCard()
                    }
                }
            }
        }
    }
}

// MARK: - Material Picker (String-based)

struct MaterialPickerStepView: View {
    let materials: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("What material?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            VStack(spacing: KISEDesign.Spacing.sm) {
                ForEach(materials, id: \.self) { material in
                    Button {
                        onSelect(material)
                    } label: {
                        Text(material.capitalized)
                            .font(KISEDesign.Typography.bodyText)
                            .foregroundStyle(KISEDesign.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(KISEDesign.Spacing.md)
                            .kiseCard()
                    }
                }
            }
        }
    }
}
