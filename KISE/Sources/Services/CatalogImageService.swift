// KISE/Sources/Services/CatalogImageService.swift
import SwiftUI

enum CatalogImageService {

    /// Builds the asset key for a given garment configuration
    static func imageKey(category: GarmentCategory, color: String, fit: Fit) -> String {
        let categoryKey = category.rawValue
            .replacingOccurrences(of: "tShirt", with: "tshirt")
        let colorKey = GarmentColor.byName(color)?.assetKey ?? color.lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return "\(categoryKey)_\(colorKey)_\(fit.rawValue)"
    }

    /// Fallback key using the default fit for the category
    static func fallbackKey(category: GarmentCategory, color: String, defaultFit: Fit) -> String {
        imageKey(category: category, color: color, fit: defaultFit)
    }

    /// Attempts to load a catalog image, trying exact match then fallback
    static func loadImage(category: GarmentCategory, color: String, fit: Fit) -> UIImage? {
        let exactKey = imageKey(category: category, color: color, fit: fit)
        if let image = UIImage(named: exactKey) {
            return image
        }

        // Fallback: same category + color, regular fit
        let fallback = fallbackKey(category: category, color: color, defaultFit: .regular)
        return UIImage(named: fallback)
    }

    /// Checks if an exact match exists in the asset catalog
    static func hasExactMatch(category: GarmentCategory, color: String, fit: Fit) -> Bool {
        let key = imageKey(category: category, color: color, fit: fit)
        return UIImage(named: key) != nil
    }
}
