// KISE/Sources/App/KISEApp.swift
import SwiftUI
import SwiftData

@main
struct KISEApp: App {
    @State private var appState = AppState()

    init() {
        BackgroundPrefetchService.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
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
                StyleOnboardingView()
            }
        }
        .onAppear {
            appState.checkOnboardingStatus(context: modelContext)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showRegistration = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                SuggestionView()
                    .tag(0)
                    .tabItem {
                        Label("Home", systemImage: "tshirt")
                    }
                WardrobeView()
                    .tag(1)
                    .tabItem {
                        Label("Wardrobe", systemImage: "cabinet")
                    }
            }
            .tint(KISEDesign.Colors.accent)

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

    @ViewBuilder
    private var addPieceButton: some View {
        let button = Button {
            showRegistration = true
        } label: {
            Image(systemName: "plus")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(KISEDesign.Colors.accent)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        if #available(iOS 26, *) {
            button.glassEffect(.regular.interactive(), in: .circle)
        } else {
            button
                .background(KISEDesign.Colors.accent, in: Circle())
        }
    }
}
