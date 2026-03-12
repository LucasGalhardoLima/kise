// KISE/Sources/Models/StyleProfile.swift
import Foundation
import SwiftData

@Model
final class StyleProfile {
    var id: UUID
    var archetypes: [StyleArchetype]
    var createdAt: Date
    var updatedAt: Date

    init(archetypes: [StyleArchetype]) {
        self.id = UUID()
        self.archetypes = archetypes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
