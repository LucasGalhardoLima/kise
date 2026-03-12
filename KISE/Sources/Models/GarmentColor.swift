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

    var needsBorder: Bool {
        let (_, s, b) = hsbComponents
        return b > 0.85 && s < 0.1
    }

    static let allColors: [GarmentColor] = [
        GarmentColor(id: "white", name: "White", hex: "#FFFFFF", isCustom: false),
        GarmentColor(id: "cream", name: "Off-White", hex: "#F5F0E8", isCustom: false),
        GarmentColor(id: "lightGray", name: "Light Gray", hex: "#C8C8C8", isCustom: false),
        GarmentColor(id: "charcoal", name: "Charcoal", hex: "#4A4A4A", isCustom: false),
        GarmentColor(id: "black", name: "Black", hex: "#1A1A1A", isCustom: false),
        GarmentColor(id: "navy", name: "Navy", hex: "#1B2A4A", isCustom: false),
        GarmentColor(id: "lightBlue", name: "Light Blue", hex: "#A4C8E8", isCustom: false),
        GarmentColor(id: "olive", name: "Olive", hex: "#6B7F4E", isCustom: false),
        GarmentColor(id: "khaki", name: "Khaki", hex: "#C4A46C", isCustom: false),
        GarmentColor(id: "brown", name: "Brown", hex: "#6B4226", isCustom: false),
        GarmentColor(id: "burgundy", name: "Burgundy", hex: "#722F37", isCustom: false),
        GarmentColor(id: "terracotta", name: "Terracotta", hex: "#C75B39", isCustom: false),
        GarmentColor(id: "sage", name: "Sage", hex: "#9CAF88", isCustom: false),
        GarmentColor(id: "indigo", name: "Indigo", hex: "#3F5277", isCustom: false),
        GarmentColor(id: "camel", name: "Camel", hex: "#C19A6B", isCustom: false),
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
        if color == "custom" {
            return GarmentColor(customHex: hex)
        }
        return byName(color) ?? GarmentColor(customHex: hex)
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
        let nearest = GarmentColor.nearestCurated(hex: customHex)
        self.id = "custom"
        self.name = "Custom \(nearest.name)"
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
