// KISE/Sources/Views/Shared/EmptyStateView.swift
import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?

    init(title: String, message: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.md) {
            Text(title)
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            Text(message)
                .font(KISEDesign.Typography.bodyText)
                .foregroundStyle(KISEDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(KISEDesign.Typography.subtitle)
                        .foregroundStyle(KISEDesign.Colors.background)
                        .padding(.horizontal, KISEDesign.Spacing.xl)
                        .padding(.vertical, KISEDesign.Spacing.md)
                        .background(KISEDesign.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
                }
            }
        }
        .padding(KISEDesign.Spacing.xl)
    }
}
