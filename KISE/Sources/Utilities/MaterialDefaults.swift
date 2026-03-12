// KISE/Sources/Utilities/MaterialDefaults.swift
import Foundation

enum MaterialDefaults {
    /// Returns the auto-suggested fabric weight for a given material
    static func weight(for material: String) -> FabricWeight {
        FabricWeight.defaultWeight(for: material)
    }

    /// Returns the auto-suggested formality for a given category
    static func formality(for category: GarmentCategory) -> Formality {
        category.defaultFormality
    }
}
