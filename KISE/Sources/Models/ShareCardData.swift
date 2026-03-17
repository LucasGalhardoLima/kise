import SwiftUI

struct ShareCardData {
    struct PieceInfo {
        let colorHex: String
        let colorName: String
        let categoryName: String
        let category: GarmentCategory
    }

    let pieces: [PieceInfo]
    let weatherLine: String?
    let brandSignature = "KISE 着せ"
    let tagline = String(localized: "share.tagline")

    /// Sorted by composition priority (outerwear → tops → bottoms → shoes)
    var sortedPieces: [PieceInfo] {
        pieces.sorted { a, b in
            CompositionLayout.sizePriority(for: a.category) > CompositionLayout.sizePriority(for: b.category)
        }
    }

    /// Piece labels joined with " · " — same format as in-app
    var pieceNamesText: String {
        sortedPieces.map { piece in
            pieceLabel(color: piece.colorName, category: piece.categoryName)
        }.joined(separator: " · ")
    }

    /// Deterministic composition layout — uses stable FNV-1a hash (not Swift's randomized hashValue)
    var layout: CompositionLayout {
        let available = CompositionLayout.templates(for: pieces.count)
        guard !available.isEmpty else { return CompositionLayout(blocks: []) }
        let key = pieces.map(\.colorHex).joined()
        let index = abs(StableHash.fnv1a(key)) % available.count
        return available[index]
    }
}

extension ShareCardData {
    /// Build from current suggestion state — eagerly snapshots values from SwiftData objects
    init(pieces: [GarmentPiece], weather: WeatherSnapshot?) {
        self.pieces = pieces.map { piece in
            PieceInfo(
                colorHex: piece.colorHex,
                colorName: piece.resolvedColorName,
                categoryName: piece.category.displayName,
                category: piece.category
            )
        }

        if let w = weather, let city = w.cityName {
            self.weatherLine = "\(city) · \(Int(w.temperature))°C · \(w.condition)"
        } else {
            self.weatherLine = nil
        }
    }
}
