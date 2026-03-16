// KISE/Sources/Models/GarmentColor.swift
import SwiftUI
import UIKit

struct GarmentColor: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String
    let isCustom: Bool

    init(id: String, name: String, hex: String, isCustom: Bool) {
        self.id = id
        self.name = name
        self.hex = hex
        self.isCustom = isCustom
    }

    var color: Color {
        Color(hex: hex)
    }

    var hsbComponents: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let c = UIColor(Color(hex: hex))
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b)
    }

    var hueSortValue: Double {
        let (h, s, b) = hsbComponents
        if s < 0.1 {
            return 2.0 + Double(b)
        }
        return Double(h)
    }

    /// Sort key for "All" wardrobe view: white → pastels → colors → darks → black
    var lightnessFirstSortValue: Double {
        let (h, s, b) = hsbComponents
        // Primary axis: brightness (inverted so white sorts first)
        // Secondary axis: hue for visual flow within similar brightness
        return (1 - b) * 0.8 + (s < 0.1 ? 0.0 : h) * 0.2
    }

    var needsBorder: Bool {
        let (_, s, b) = hsbComponents
        return b > 0.85 && s < 0.1
    }

    static let allColors: [GarmentColor] = [
        // Whites & Neutrals
        GarmentColor(id: "white", name: "White", hex: "#FFFFFF", isCustom: false),
        GarmentColor(id: "cream", name: "Ivory Cream", hex: "#F5F0E8", isCustom: false),
        GarmentColor(id: "beige", name: "Sand Dune", hex: "#D4C5A9", isCustom: false),
        GarmentColor(id: "tan", name: "Raw Umber", hex: "#C2956B", isCustom: false),
        // Grays
        GarmentColor(id: "lightGray", name: "Silver Mist", hex: "#C8C8C8", isCustom: false),
        GarmentColor(id: "charcoal", name: "Charcoal", hex: "#4A4A4A", isCustom: false),
        GarmentColor(id: "black", name: "Black", hex: "#1A1A1A", isCustom: false),
        // Blues
        GarmentColor(id: "navy", name: "Midnight Navy", hex: "#1B2A4A", isCustom: false),
        GarmentColor(id: "lightBlue", name: "Sky Blue", hex: "#A4C8E8", isCustom: false),
        GarmentColor(id: "indigo", name: "Dusk Indigo", hex: "#3F5277", isCustom: false),
        GarmentColor(id: "teal", name: "Deep Teal", hex: "#2E8B8B", isCustom: false),
        // Greens
        GarmentColor(id: "olive", name: "Moss Olive", hex: "#6B7F4E", isCustom: false),
        GarmentColor(id: "sage", name: "Dusty Sage", hex: "#9CAF88", isCustom: false),
        // Warm tones
        GarmentColor(id: "camel", name: "Caramel", hex: "#C19A6B", isCustom: false),
        GarmentColor(id: "khaki", name: "Warm Khaki", hex: "#C4A46C", isCustom: false),
        GarmentColor(id: "mustard", name: "Aged Gold", hex: "#D4A520", isCustom: false),
        GarmentColor(id: "coral", name: "Dusty Coral", hex: "#E8826A", isCustom: false),
        GarmentColor(id: "terracotta", name: "Terracotta", hex: "#C75B39", isCustom: false),
        // Cool tones
        GarmentColor(id: "lavender", name: "Wisteria", hex: "#B4A7D6", isCustom: false),
        // Deep tones
        GarmentColor(id: "brown", name: "Dark Cocoa", hex: "#6B4226", isCustom: false),
        GarmentColor(id: "burgundy", name: "Burgundy Wine", hex: "#722F37", isCustom: false),
        GarmentColor(id: "maroon", name: "Dark Wine", hex: "#5B1E31", isCustom: false),
    ]

    static func byName(_ name: String) -> GarmentColor? {
        allColors.first { $0.name.lowercased() == name.lowercased() || $0.id == name.lowercased() }
    }

    static func nearestCurated(hex: String) -> GarmentColor {
        let target = Self.rgbComponents(hex: hex)
        var best = allColors[0]
        var bestDist = Double.infinity
        for color in allColors {
            let c = rgbComponents(hex: color.hex)
            let dist = pow(target.r - c.r, 2) + pow(target.g - c.g, 2) + pow(target.b - c.b, 2)
            if dist < bestDist {
                bestDist = dist
                best = color
            }
        }
        return best
    }

    static func resolve(color: String, hex: String) -> GarmentColor {
        if color.hasPrefix("custom") {  // matches both "custom" (legacy) and "custom-XXXXXX"
            return GarmentColor(customHex: hex)
        }
        return allColors.first { $0.id == color } ?? GarmentColor(customHex: hex)
    }

    private static func rgbComponents(hex: String) -> (r: Double, g: Double, b: Double) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        return (
            Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}

extension GarmentColor {
    init(customHex: String) {
        let hexClean = customHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        self.id = "custom-\(hexClean)"
        self.name = "Custom"  // Placeholder — replaced by ColorNamingService
        self.hex = customHex
        self.isCustom = true
    }
}

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
