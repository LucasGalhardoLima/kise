// KISE/Sources/Views/Registration/AttributeStepView.swift
import SwiftUI

// MARK: - Generic Option Picker Step

struct OptionPickerStepView<T: Identifiable>: View where T: Equatable {
    @Environment(ThemeProvider.self) private var theme
    let title: String
    let options: [T]
    let labelFor: (T) -> String
    let suggested: T?
    let onSelect: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text(title)
                .font(KISEDesign.Typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            VStack(spacing: KISEDesign.Spacing.sm) {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        HStack {
                            Text(labelFor(option))
                                .font(KISEDesign.Typography.bodyText)
                                .foregroundStyle(theme.colors.textPrimary)

                            Spacer()

                            if let suggested, suggested.id as AnyHashable == option.id as AnyHashable {
                                Text("registration.suggested")
                                    .font(KISEDesign.Typography.small)
                                    .foregroundStyle(theme.colors.textTertiary)
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
    @Environment(ThemeProvider.self) private var theme
    let materials: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("registration.whatMaterial")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            VStack(spacing: KISEDesign.Spacing.sm) {
                ForEach(materials, id: \.self) { material in
                    Button {
                        onSelect(material)
                    } label: {
                        Text(materialDisplayName(material))
                            .font(KISEDesign.Typography.bodyText)
                            .foregroundStyle(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(KISEDesign.Spacing.md)
                            .kiseCard()
                    }
                }
            }
        }
    }
}
