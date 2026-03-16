// KISE/Sources/Models/Enums.swift
import Foundation

// MARK: - Tab Groups

enum TabGroup: String, CaseIterable {
    case tops, bottoms, outerwear, shoes
}

// MARK: - Garment Category

enum GarmentCategory: String, Codable, CaseIterable, Identifiable {
    case tShirt, shirt, polo, sweater, hoodie
    case jacket, coat
    case jeans, chinos, shorts
    case shoes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tShirt: "T-Shirt"
        case .shirt: "Shirt"
        case .polo: "Polo"
        case .sweater: "Sweater"
        case .hoodie: "Hoodie"
        case .jacket: "Jacket"
        case .coat: "Coat"
        case .jeans: "Jeans"
        case .chinos: "Chinos"
        case .shorts: "Shorts"
        case .shoes: "Shoes"
        }
    }

    var tabGroup: TabGroup {
        switch self {
        case .tShirt, .shirt, .polo, .sweater, .hoodie: .tops
        case .jeans, .chinos, .shorts: .bottoms
        case .jacket, .coat: .outerwear
        case .shoes: .shoes
        }
    }

    var availableFits: [Fit] {
        switch self {
        case .jeans, .chinos: [.slim, .regular, .relaxed, .straight]
        case .shorts: [.slim, .regular, .relaxed]
        case .tShirt, .shirt, .polo, .sweater, .hoodie: [.slim, .regular, .oversized]
        case .jacket, .coat: [.slim, .regular, .oversized]
        case .shoes: [.regular]
        }
    }

    var availableMaterials: [String] {
        switch self {
        case .tShirt, .polo: ["cotton", "linen", "synthetic", "tricot", "jersey"]
        case .shirt: ["cotton", "linen", "synthetic", "flannel", "silk"]
        case .sweater: ["cotton", "wool", "cashmere", "synthetic", "tricot"]
        case .hoodie: ["cotton", "synthetic", "jersey"]
        case .jacket: ["cotton", "linen", "wool", "leather", "synthetic", "nylon", "fleece"]
        case .coat: ["wool", "cotton", "synthetic", "down", "nylon", "fleece"]
        case .jeans: ["denim"]
        case .chinos: ["cotton", "linen", "corduroy"]
        case .shorts: ["cotton", "linen", "denim", "synthetic", "jogger"]
        case .shoes: ["leather", "suede", "canvas", "synthetic", "mesh"]
        }
    }

    var defaultFormality: Formality {
        switch self {
        case .tShirt, .hoodie, .shorts: .casual
        case .polo, .sweater, .jeans, .chinos: .smartCasual
        case .shirt, .jacket, .coat, .shoes: .smartCasual
        }
    }
}

// MARK: - Fit

enum Fit: String, Codable, CaseIterable, Identifiable {
    case slim, regular, relaxed, straight, oversized

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Shoe Type

enum ShoeType: String, Codable, CaseIterable, Identifiable {
    case sneakers, loafers, boots, oxfords, sandals, slides

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sneakers: "Sneakers"
        case .loafers: "Loafers"
        case .boots: "Boots"
        case .oxfords: "Oxfords"
        case .sandals: "Sandals"
        case .slides: "Slides"
        }
    }
}

// MARK: - Fabric Weight

enum FabricWeight: String, Codable, CaseIterable, Identifiable {
    case light, mid, heavy

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    static func defaultWeight(for material: String) -> FabricWeight {
        switch material.lowercased() {
        case "linen", "silk", "mesh": .light
        case "cotton", "denim", "suede", "canvas", "jersey", "nylon": .mid
        case "wool", "cashmere", "leather", "down", "corduroy", "flannel", "fleece": .heavy
        case "synthetic", "tricot", "jogger": .light
        default: .mid
        }
    }
}

// MARK: - Formality

enum Formality: String, Codable, CaseIterable, Identifiable {
    case casual, smartCasual, formal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .casual: "Casual"
        case .smartCasual: "Smart Casual"
        case .formal: "Formal"
        }
    }
}

// MARK: - Occasion

enum Occasion: String, Codable, CaseIterable, Identifiable {
    case everyday, meeting, dateNight, nightOut

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .everyday: "Everyday"
        case .meeting: "Meeting"
        case .dateNight: "Date Night"
        case .nightOut: "Night Out"
        }
    }
}

// MARK: - Style Archetype

enum StyleArchetype: String, Codable, CaseIterable, Identifiable {
    case oldMoney, minimalist, smartCasual, streetwear, classic, scandinavian

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oldMoney: "Old Money"
        case .minimalist: "Minimalist"
        case .smartCasual: "Smart Casual"
        case .streetwear: "Streetwear"
        case .classic: "Classic"
        case .scandinavian: "Scandinavian"
        }
    }

    /// Key used for asset names and API payloads
    var assetKey: String {
        switch self {
        case .oldMoney: "old-money"
        case .minimalist: "minimalist"
        case .smartCasual: "smart-casual"
        case .streetwear: "streetwear"
        case .classic: "classic"
        case .scandinavian: "scandinavian"
        }
    }

    /// SF Symbol for placeholder cards (until moodboard images are added)
    var placeholderIcon: String {
        switch self {
        case .oldMoney: "crown"
        case .minimalist: "circle.grid.2x1"
        case .smartCasual: "briefcase"
        case .streetwear: "shoe.2"
        case .classic: "shield.checkered"
        case .scandinavian: "leaf"
        }
    }
}
