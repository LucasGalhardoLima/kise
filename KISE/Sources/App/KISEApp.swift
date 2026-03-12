// KISE/Sources/App/KISEApp.swift
import SwiftUI
import SwiftData

@main
struct KISEApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
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
                StyleOnboardingView()
            }
        }
        .onAppear {
            appState.checkOnboardingStatus(context: modelContext)
        }
    }
}

struct MainTabView: View {
    @State private var showSettings = false

    var body: some View {
        TabView {
            SuggestionView()
                .tabItem {
                    Label("Home", systemImage: "tshirt")
                }
            WardrobeView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(KISEDesign.Colors.textSecondary)
                        }
                    }
                }
                .tabItem {
                    Label("Wardrobe", systemImage: "cabinet")
                }
        }
        .tint(KISEDesign.Colors.accent)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
