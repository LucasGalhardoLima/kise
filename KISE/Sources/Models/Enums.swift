// KISE/Sources/Models/Enums.swift
import Foundation

// MARK: - Tab Groups

enum TabGroup: String, CaseIterable {
    case tops, bottoms, outerwear, shoes

    var displayName: String {
        switch self {
        case .tops: String(localized: "tabGroup.tops")
        case .bottoms: String(localized: "tabGroup.bottoms")
        case .outerwear: String(localized: "tabGroup.outerwear")
        case .shoes: String(localized: "tabGroup.shoes")
        }
    }
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
        case .tShirt: String(localized: "category.tShirt")
        case .shirt: String(localized: "category.shirt")
        case .polo: String(localized: "category.polo")
        case .sweater: String(localized: "category.sweater")
        case .hoodie: String(localized: "category.hoodie")
        case .jacket: String(localized: "category.jacket")
        case .coat: String(localized: "category.coat")
        case .jeans: String(localized: "category.jeans")
        case .chinos: String(localized: "category.chinos")
        case .shorts: String(localized: "category.shorts")
        case .shoes: String(localized: "category.shoes")
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

    var displayName: String {
        switch self {
        case .slim: String(localized: "fit.slim")
        case .regular: String(localized: "fit.regular")
        case .relaxed: String(localized: "fit.relaxed")
        case .straight: String(localized: "fit.straight")
        case .oversized: String(localized: "fit.oversized")
        }
    }
}

// MARK: - Shoe Type

enum ShoeType: String, Codable, CaseIterable, Identifiable {
    case sneakers, loafers, boots, oxfords, sandals, slides

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sneakers: String(localized: "shoeType.sneakers")
        case .loafers: String(localized: "shoeType.loafers")
        case .boots: String(localized: "shoeType.boots")
        case .oxfords: String(localized: "shoeType.oxfords")
        case .sandals: String(localized: "shoeType.sandals")
        case .slides: String(localized: "shoeType.slides")
        }
    }
}

// MARK: - Fabric Weight

enum FabricWeight: String, Codable, CaseIterable, Identifiable {
    case light, mid, heavy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: String(localized: "weight.light")
        case .mid: String(localized: "weight.mid")
        case .heavy: String(localized: "weight.heavy")
        }
    }

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
        case .casual: String(localized: "formality.casual")
        case .smartCasual: String(localized: "formality.smartCasual")
        case .formal: String(localized: "formality.formal")
        }
    }
}

// MARK: - Occasion

enum Occasion: String, Codable, CaseIterable, Identifiable {
    case everyday, meeting, dateNight, nightOut

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .everyday: String(localized: "occasion.everyday")
        case .meeting: String(localized: "occasion.meeting")
        case .dateNight: String(localized: "occasion.dateNight")
        case .nightOut: String(localized: "occasion.nightOut")
        }
    }
}

// MARK: - Style Archetype

enum StyleArchetype: String, Codable, CaseIterable, Identifiable {
    case oldMoney, minimalist, smartCasual, streetwear, classic, scandinavian

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oldMoney: String(localized: "archetype.oldMoney")
        case .minimalist: String(localized: "archetype.minimalist")
        case .smartCasual: String(localized: "archetype.smartCasual")
        case .streetwear: String(localized: "archetype.streetwear")
        case .classic: String(localized: "archetype.classic")
        case .scandinavian: String(localized: "archetype.scandinavian")
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

// MARK: - Material Display Names

func materialDisplayName(_ material: String) -> String {
    switch material.lowercased() {
    case "cotton": String(localized: "material.cotton")
    case "linen": String(localized: "material.linen")
    case "synthetic": String(localized: "material.synthetic")
    case "tricot": String(localized: "material.tricot")
    case "jersey": String(localized: "material.jersey")
    case "flannel": String(localized: "material.flannel")
    case "silk": String(localized: "material.silk")
    case "wool": String(localized: "material.wool")
    case "cashmere": String(localized: "material.cashmere")
    case "leather": String(localized: "material.leather")
    case "nylon": String(localized: "material.nylon")
    case "fleece": String(localized: "material.fleece")
    case "denim": String(localized: "material.denim")
    case "corduroy": String(localized: "material.corduroy")
    case "down": String(localized: "material.down")
    case "jogger": String(localized: "material.jogger")
    case "suede": String(localized: "material.suede")
    case "canvas": String(localized: "material.canvas")
    case "mesh": String(localized: "material.mesh")
    default: material.capitalized
    }
}

/// Localized piece label: "Black Shoes" (en) / "Calçados Pretos" (pt-BR)
func pieceLabel(color: String, category: String) -> String {
    String(format: String(localized: "pieceLabel.colorCategory"), color, category)
}
