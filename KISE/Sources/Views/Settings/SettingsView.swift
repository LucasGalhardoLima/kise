// KISE/Sources/Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedArchetypes: Set<StyleArchetype> = []

    @Query private var profiles: [StyleProfile]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        archetypeEditor
                    } label: {
                        HStack {
                            Text("Style archetypes")
                                .font(KISEDesign.Typography.bodyText)
                            Spacer()
                            Text(currentArchetypesSummary)
                                .font(KISEDesign.Typography.caption)
                                .foregroundStyle(KISEDesign.Colors.textSecondary)
                        }
                    }
                } header: {
                    Text("Style")
                        .font(KISEDesign.Typography.caption)
                }

                Section {
                    HStack {
                        Text("Version")
                            .font(KISEDesign.Typography.bodyText)
                        Spacer()
                        Text("1.0.0")
                            .font(KISEDesign.Typography.caption)
                            .foregroundStyle(KISEDesign.Colors.textSecondary)
                    }
                } header: {
                    Text("About")
                        .font(KISEDesign.Typography.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(KISEDesign.Typography.subtitle)
                }
            }
        }
        .onAppear {
            if let profile = profiles.first {
                selectedArchetypes = Set(profile.archetypes)
            }
        }
    }

    private var currentArchetypesSummary: String {
        guard let profile = profiles.first else { return "None" }
        return profile.archetypes.map(\.displayName).joined(separator: ", ")
    }

    private var archetypeEditor: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: KISEDesign.Spacing.md) {
                ForEach(StyleArchetype.allCases) { archetype in
                    Button {
                        toggleArchetype(archetype)
                    } label: {
                        VStack(spacing: KISEDesign.Spacing.sm) {
                            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                .fill(KISEDesign.Colors.surface)
                                .frame(height: 100)
                                .overlay(
                                    Text(archetype.displayName)
                                        .font(KISEDesign.Typography.subtitle)
                                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                        .strokeBorder(
                                            selectedArchetypes.contains(archetype) ? KISEDesign.Colors.accent : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .kiseCard()
                        }
                    }
                }
            }
            .padding(KISEDesign.Spacing.md)
        }
        .navigationTitle("Style Archetypes")
        .background(KISEDesign.Colors.background)
    }

    private func toggleArchetype(_ archetype: StyleArchetype) {
        if selectedArchetypes.contains(archetype) {
            // Don't allow deselecting the last one
            guard selectedArchetypes.count > 1 else { return }
            selectedArchetypes.remove(archetype)
        } else {
            selectedArchetypes.insert(archetype)
        }

        // Update the profile
        if let profile = profiles.first {
            profile.archetypes = Array(selectedArchetypes)
            profile.updatedAt = Date()
            try? modelContext.save()
        }
    }
}
