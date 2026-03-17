// KISE/Sources/App/KISEApp.swift
import SwiftUI
import SwiftData

@main
struct KISEApp: App {
    @State private var appState = AppState()
    @State private var themeProvider = ThemeProvider()

    init() {
        BackgroundPrefetchService.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(themeProvider)
                .onAppear {
                    BackgroundPrefetchService.scheduleNextRefresh()
                }
        }
        .modelContainer(for: [
            StyleProfile.self,
            GarmentPiece.self,
            OutfitSuggestion.self,
            Feedback.self,
        ])
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .onAppear {
            appState.checkOnboardingStatus(context: modelContext)
        }
    }
}

struct MainTabView: View {
    @Environment(ThemeProvider.self) private var theme
    @State private var selectedTab = 0
    @State private var showRegistration = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                SuggestionView()
                    .tag(0)
                    .tabItem {
                        Label(String(localized: "tab.home"), systemImage: "tshirt")
                    }
                WardrobeView()
                    .tag(1)
                    .tabItem {
                        Label(String(localized: "tab.wardrobe"), systemImage: "cabinet")
                    }
                SettingsView()
                    .tag(2)
                    .tabItem {
                        Label(String(localized: "tab.settings"), systemImage: "gearshape")
                    }
            }
            .tint(theme.colors.accent)

            if selectedTab == 1 {
                addPieceButton
                    .padding(.trailing, KISEDesign.Spacing.lg)
                    .offset(y: 6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .sheet(isPresented: $showRegistration) {
            RegistrationFlowView()
        }
    }

    private var addPieceButton: some View {
        Button {
            showRegistration = true
        } label: {
            Circle()
                .fill(theme.colors.accent)
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .overlay(
                    Image(systemName: "plus")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white)
                )
        }
        .buttonStyle(.plain)
    }
}
