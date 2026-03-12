// KISE/Sources/Models/Feedback.swift
import Foundation
import SwiftData

@Model
final class Feedback {
    var id: UUID
    var liked: Bool
    var dislikeReason: String?
    var dislikedPieceID: UUID?
    var createdAt: Date

    init(liked: Bool) {
        self.id = UUID()
        self.liked = liked
        self.dislikeReason = nil
        self.dislikedPieceID = nil
        self.createdAt = Date()
    }

    /// Serializes for the suggestion request payload
    var payloadValue: String {
        liked ? "liked" : "disliked"
    }
}
