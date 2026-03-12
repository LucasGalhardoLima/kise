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
    var body: some View {
        TabView {
            Text("Suggestions coming soon")
                .tabItem {
                    Label("Home", systemImage: "tshirt")
                }
            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "cabinet")
                }
        }
        .tint(KISEDesign.Colors.accent)
    }
}
