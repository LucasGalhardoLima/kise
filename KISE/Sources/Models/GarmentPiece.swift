// KISE/Sources/Models/GarmentPiece.swift
import Foundation
import SwiftData

@Model
final class GarmentPiece {
    var id: UUID
    var category: GarmentCategory
    var color: String
    var colorHex: String
    var fit: Fit
    var material: String
    var weight: FabricWeight
    var formality: Formality
    var userPhotoPath: String?
    var isActive: Bool
    var createdAt: Date

    /// Computed catalog image asset key: {category}_{color}_{fit}
    var catalogImageID: String {
        let colorKey = GarmentColor.byName(color)?.assetKey ?? color.lowercased()
        return "\(category.rawValue)_\(colorKey)_\(fit.rawValue)"
            .replacingOccurrences(of: "tShirt", with: "tshirt")
    }

    init(
        category: GarmentCategory,
        color: String,
        colorHex: String,
        fit: Fit,
        material: String,
        weight: FabricWeight,
        formality: Formality
    ) {
        self.id = UUID()
        self.category = category
        self.color = color
        self.colorHex = colorHex
        self.fit = fit
        self.material = material
        self.weight = weight
        self.formality = formality
        self.userPhotoPath = nil
        self.isActive = true
        self.createdAt = Date()
    }
}
