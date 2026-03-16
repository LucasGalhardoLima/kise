// KISE/Sources/Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StyleProfile]

    @AppStorage("temperatureUnit") private var temperatureUnit = "celsius"
    @AppStorage("defaultOccasion") private var defaultOccasion = "everyday"
    @AppStorage("morningNotification") private var morningNotification = false
    @AppStorage("notificationHour") private var notificationHour = 7
    @AppStorage("notificationMinute") private var notificationMinute = 30

    @State private var selectedArchetypes: Set<StyleArchetype> = []

    var body: some View {
        NavigationStack {
            List {
                // Profile
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
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("Profile")
                        .font(KISEDesign.Typography.caption)
                }

                // Preferences
                Section {
                    // Temperature unit
                    HStack {
                        Text("Temperature")
                            .font(KISEDesign.Typography.bodyText)
                        Spacer()
                        Picker("", selection: $temperatureUnit) {
                            Text("°C").tag("celsius")
                            Text("°F").tag("fahrenheit")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }

                    // Default occasion
                    Picker(selection: $defaultOccasion) {
                        ForEach(Occasion.allCases) { occasion in
                            Text(occasion.displayName).tag(occasion.rawValue)
                        }
                    } label: {
                        Text("Default occasion")
                            .font(KISEDesign.Typography.bodyText)
                    }

                    // Morning notification
                    Toggle(isOn: $morningNotification) {
                        Text("Morning reminder")
                            .font(KISEDesign.Typography.bodyText)
                    }
                    .tint(KISEDesign.Colors.accent)
                    .onChange(of: morningNotification) { _, enabled in
                        if enabled {
                            requestNotificationPermission()
                        }
                        scheduleNotification()
                    }

                    if morningNotification {
                        DatePicker(
                            "Reminder time",
                            selection: notificationTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .font(KISEDesign.Typography.bodyText)
                        .onChange(of: notificationHour) { _, _ in scheduleNotification() }
                        .onChange(of: notificationMinute) { _, _ in scheduleNotification() }
                    }
                } header: {
                    Text("Preferences")
                        .font(KISEDesign.Typography.caption)
                }

                // Appearance
                Section {
                    HStack {
                        Text("Theme")
                            .font(KISEDesign.Typography.bodyText)
                        Spacer()
                        Text("Default")
                            .font(KISEDesign.Typography.caption)
                            .foregroundStyle(KISEDesign.Colors.textSecondary)
                    }
                    Text("More themes coming soon")
                        .font(KISEDesign.Typography.small)
                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                } header: {
                    Text("Appearance")
                        .font(KISEDesign.Typography.caption)
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                            .font(KISEDesign.Typography.bodyText)
                        Spacer()
                        Text("1.0.0")
                            .font(KISEDesign.Typography.caption)
                            .foregroundStyle(KISEDesign.Colors.textSecondary)
                    }
                    Text("Made with intention")
                        .font(KISEDesign.Typography.small)
                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } header: {
                    Text("About")
                        .font(KISEDesign.Typography.caption)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                }
            }
        }
        .onAppear {
            if let profile = profiles.first {
                selectedArchetypes = Set(profile.archetypes)
            }
        }
    }

    // MARK: - Notification Time Binding

    private var notificationTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = notificationHour
                components.minute = notificationMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = components.hour ?? 7
                notificationMinute = components.minute ?? 30
            }
        )
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morning-outfit"])

        guard morningNotification else { return }

        let content = UNMutableNotificationContent()
        content.title = "KISE"
        content.body = "Your outfit is ready"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-outfit", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Archetypes

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
            guard selectedArchetypes.count > 1 else { return }
            selectedArchetypes.remove(archetype)
        } else {
            selectedArchetypes.insert(archetype)
        }

        if let profile = profiles.first {
            profile.archetypes = Array(selectedArchetypes)
            profile.updatedAt = Date()
            try? modelContext.save()
        }
    }
}
