// KISE/Sources/Views/Registration/AttributeStepView.swift
import SwiftUI

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
