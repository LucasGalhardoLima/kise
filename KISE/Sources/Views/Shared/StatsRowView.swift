// KISE/Sources/Views/Shared/StatsRowView.swift
import SwiftUI

struct StatItem: Identifiable {
    let count: Int
    let label: String
    var displayValue: String?
    var action: (() -> Void)?
    var id: String { label }
}

struct StatsRowView: View {
    let items: [StatItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Divider()
                        .frame(height: 32)
                        .padding(.horizontal, KISEDesign.Spacing.sm)
                }
                statColumn(item)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KISEDesign.Spacing.sm)
    }

    private func statColumn(_ item: StatItem) -> some View {
        Group {
            if let action = item.action {
                Button(action: action) { statContent(item) }
                    .buttonStyle(.plain)
            } else {
                statContent(item)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statContent(_ item: StatItem) -> some View {
        VStack(spacing: KISEDesign.Spacing.xs) {
            Text(item.displayValue ?? "\(item.count)")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)
            Text(item.label)
                .kiseSectionLabel()
        }
    }
}
