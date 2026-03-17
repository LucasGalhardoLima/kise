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
        .addPieceAccessory(
            isVisible: selectedTab == 1,
            theme: theme,
            action: { showRegistration = true }
        )
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .sheet(isPresented: $showRegistration) {
            RegistrationFlowView()
        }
    }
}

// MARK: - Add Piece Accessory (iOS 26 vs fallback)

private struct AddPieceAccessoryModifier: ViewModifier {
    let isVisible: Bool
    let theme: ThemeProvider
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.tabViewBottomAccessory(isEnabled: isVisible) {
                addButton
            }
        } else {
            ZStack(alignment: .bottomTrailing) {
                content
                if isVisible {
                    addButton
                        .padding(.trailing, KISEDesign.Spacing.lg)
                        .padding(.bottom, 60)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: action) {
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

private extension View {
    func addPieceAccessory(isVisible: Bool, theme: ThemeProvider, action: @escaping () -> Void) -> some View {
        modifier(AddPieceAccessoryModifier(isVisible: isVisible, theme: theme, action: action))
    }
}
