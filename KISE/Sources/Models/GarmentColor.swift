// KISE/Sources/Models/GarmentColor.swift
import SwiftUI

struct GarmentColor: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String
    let assetKey: String

    var color: Color {
        Color(hex: hex)
    }

    static let allColors: [GarmentColor] = [
        GarmentColor(id: "white", name: "White", hex: "#FFFFFF", assetKey: "white"),
        GarmentColor(id: "cream", name: "Off-White", hex: "#F5F0E8", assetKey: "cream"),
        GarmentColor(id: "lightGray", name: "Light Gray", hex: "#C8C8C8", assetKey: "light-gray"),
        GarmentColor(id: "charcoal", name: "Charcoal", hex: "#4A4A4A", assetKey: "charcoal"),
        GarmentColor(id: "black", name: "Black", hex: "#1A1A1A", assetKey: "black"),
        GarmentColor(id: "navy", name: "Navy", hex: "#1B2A4A", assetKey: "navy"),
        GarmentColor(id: "lightBlue", name: "Light Blue", hex: "#A4C8E8", assetKey: "light-blue"),
        GarmentColor(id: "olive", name: "Olive", hex: "#6B7F4E", assetKey: "olive"),
        GarmentColor(id: "khaki", name: "Khaki", hex: "#C4A46C", assetKey: "khaki"),
        GarmentColor(id: "brown", name: "Brown", hex: "#6B4226", assetKey: "brown"),
        GarmentColor(id: "burgundy", name: "Burgundy", hex: "#722F37", assetKey: "burgundy"),
        GarmentColor(id: "terracotta", name: "Terracotta", hex: "#C75B39", assetKey: "terracotta"),
        GarmentColor(id: "sage", name: "Sage", hex: "#9CAF88", assetKey: "sage"),
        GarmentColor(id: "indigo", name: "Indigo", hex: "#3F5277", assetKey: "indigo"),
        GarmentColor(id: "camel", name: "Camel", hex: "#C19A6B", assetKey: "camel"),
    ]

    static func byName(_ name: String) -> GarmentColor? {
        allColors.first { $0.name.lowercased() == name.lowercased() || $0.id == name.lowercased() }
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
