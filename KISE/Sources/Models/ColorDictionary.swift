// KISE/Sources/Models/ColorDictionary.swift
import Foundation

/// Named color dictionary for pre-iOS 26 fallback color naming.
/// Expand to ~150 entries for good coverage — the entries below are a starting set (~80).
/// Add more as needed: warm pinks, deeper oranges, olive/military greens, dusty blues, warm grays, earth tones.
enum ColorDictionary {
    struct NamedColor {
        let hex: String
        let name: String

        var rgb: (r: Double, g: Double, b: Double) {
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

    static let entries: [NamedColor] = [
        // Whites & Creams
        NamedColor(hex: "#FFFAF0", name: "Floral White"),
        NamedColor(hex: "#FAF0E6", name: "Linen"),
        NamedColor(hex: "#FFF5EE", name: "Seashell"),
        NamedColor(hex: "#F5F5DC", name: "Vanilla Cream"),
        NamedColor(hex: "#FFFFF0", name: "Ivory"),
        NamedColor(hex: "#F0EAD6", name: "Eggshell"),
        // Soft Pinks
        NamedColor(hex: "#FFE4E1", name: "Misty Rose"),
        NamedColor(hex: "#FFC0CB", name: "Blush Pink"),
        NamedColor(hex: "#FFB6C1", name: "Light Rose"),
        NamedColor(hex: "#DB7093", name: "Dusty Rose"),
        NamedColor(hex: "#C08081", name: "Antique Rose"),
        NamedColor(hex: "#8B6F6F", name: "Dusty Mauve"),
        // Reds
        NamedColor(hex: "#CD5C5C", name: "Indian Red"),
        NamedColor(hex: "#B22222", name: "Firebrick"),
        NamedColor(hex: "#8B0000", name: "Dark Crimson"),
        NamedColor(hex: "#DC143C", name: "Crimson"),
        NamedColor(hex: "#800020", name: "Burgundy Wine"),
        // Oranges
        NamedColor(hex: "#FF8C69", name: "Salmon"),
        NamedColor(hex: "#E97451", name: "Burnt Sienna"),
        NamedColor(hex: "#CC5500", name: "Burnt Orange"),
        NamedColor(hex: "#FF7F50", name: "Coral Reef"),
        NamedColor(hex: "#E2725B", name: "Terra Rosa"),
        NamedColor(hex: "#D2691E", name: "Cinnamon"),
        // Yellows & Golds
        NamedColor(hex: "#FFD700", name: "Gold"),
        NamedColor(hex: "#DAA520", name: "Goldenrod"),
        NamedColor(hex: "#F0E68C", name: "Pale Gold"),
        NamedColor(hex: "#BDB76B", name: "Dark Khaki"),
        NamedColor(hex: "#FFDB58", name: "Mustard Yellow"),
        NamedColor(hex: "#E8D44D", name: "Citrine"),
        // Browns & Tans
        NamedColor(hex: "#DEB887", name: "Warm Sand"),
        NamedColor(hex: "#D2B48C", name: "Desert Tan"),
        NamedColor(hex: "#C19A6B", name: "Caramel"),
        NamedColor(hex: "#A0522D", name: "Russet"),
        NamedColor(hex: "#8B4513", name: "Saddle Brown"),
        NamedColor(hex: "#6B4226", name: "Dark Cocoa"),
        NamedColor(hex: "#3C1414", name: "Dark Chocolate"),
        NamedColor(hex: "#704214", name: "Sepia"),
        // Greens
        NamedColor(hex: "#98FB98", name: "Mint"),
        NamedColor(hex: "#90EE90", name: "Spring Green"),
        NamedColor(hex: "#8FBC8F", name: "Sage Mist"),
        NamedColor(hex: "#9CAF88", name: "Dusty Sage"),
        NamedColor(hex: "#6B8E23", name: "Olive Drab"),
        NamedColor(hex: "#556B2F", name: "Dark Olive"),
        NamedColor(hex: "#2E8B57", name: "Sea Green"),
        NamedColor(hex: "#355E3B", name: "Hunter Green"),
        NamedColor(hex: "#013220", name: "Dark Forest"),
        NamedColor(hex: "#228B22", name: "Forest Green"),
        NamedColor(hex: "#4F7942", name: "Fern"),
        // Teals & Cyans
        NamedColor(hex: "#008B8B", name: "Deep Teal"),
        NamedColor(hex: "#20B2AA", name: "Light Teal"),
        NamedColor(hex: "#5F9EA0", name: "Cadet Blue"),
        NamedColor(hex: "#7FFFD4", name: "Aquamarine"),
        NamedColor(hex: "#66CDAA", name: "Seafoam"),
        // Blues
        NamedColor(hex: "#B0C4DE", name: "Steel Blue"),
        NamedColor(hex: "#87CEEB", name: "Sky Blue"),
        NamedColor(hex: "#6495ED", name: "Cornflower"),
        NamedColor(hex: "#4169E1", name: "Royal Blue"),
        NamedColor(hex: "#1B2A4A", name: "Midnight Navy"),
        NamedColor(hex: "#191970", name: "Midnight Blue"),
        NamedColor(hex: "#000080", name: "Deep Navy"),
        NamedColor(hex: "#4682B4", name: "Ocean Blue"),
        NamedColor(hex: "#708090", name: "Slate"),
        NamedColor(hex: "#2F4F4F", name: "Dark Slate"),
        // Purples & Violets
        NamedColor(hex: "#E6E6FA", name: "Soft Lavender"),
        NamedColor(hex: "#B4A7D6", name: "Wisteria"),
        NamedColor(hex: "#9370DB", name: "Medium Purple"),
        NamedColor(hex: "#8B008B", name: "Dark Magenta"),
        NamedColor(hex: "#663399", name: "Royal Purple"),
        NamedColor(hex: "#4B0082", name: "Deep Indigo"),
        NamedColor(hex: "#9966CC", name: "Amethyst"),
        NamedColor(hex: "#7B68EE", name: "Periwinkle"),
        // Grays
        NamedColor(hex: "#F5F5F5", name: "Snow"),
        NamedColor(hex: "#DCDCDC", name: "Silver"),
        NamedColor(hex: "#C0C0C0", name: "Pearl Gray"),
        NamedColor(hex: "#A9A9A9", name: "Pewter"),
        NamedColor(hex: "#808080", name: "Stone"),
        NamedColor(hex: "#696969", name: "Smoke"),
        NamedColor(hex: "#505050", name: "Graphite"),
        NamedColor(hex: "#363636", name: "Charcoal"),
        NamedColor(hex: "#1C1C1C", name: "Onyx"),
    ]

    /// Find the nearest named color by RGB distance
    static func nearestName(for hex: String) -> String {
        let target = targetRGB(hex: hex)
        var bestName = "Unique"
        var bestDist = Double.infinity
        for entry in entries {
            let c = entry.rgb
            let dist = pow(target.r - c.r, 2) + pow(target.g - c.g, 2) + pow(target.b - c.b, 2)
            if dist < bestDist {
                bestDist = dist
                bestName = entry.name
            }
        }
        return bestName
    }

    private static func targetRGB(hex: String) -> (r: Double, g: Double, b: Double) {
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
