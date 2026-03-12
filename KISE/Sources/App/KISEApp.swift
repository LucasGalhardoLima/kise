// KISE/Sources/App/KISEApp.swift
import SwiftUI
import SwiftData

@main
struct KISEApp: App {
    var body: some Scene {
        WindowGroup {
            Text("KISE")
        }
        .modelContainer(for: [
            StyleProfile.self,
            GarmentPiece.self,
            OutfitSuggestion.self,
            Feedback.self,
        ])
    }
}
