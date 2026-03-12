// KISE/Sources/Models/CompositionLayout.swift
import Foundation

struct CompositionBlock: Equatable {
    let relativeX: Double
    let relativeY: Double
    let relativeWidth: Double
    let relativeHeight: Double
}

struct CompositionLayout: Equatable {
    let blocks: [CompositionBlock]

    static func templates(for pieceCount: Int) -> [CompositionLayout] {
        let clamped = min(max(pieceCount, 1), 5)
        switch clamped {
        case 1:
            return [
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.1, relativeY: 0.1, relativeWidth: 0.8, relativeHeight: 0.8),
                ]),
            ]
        case 2:
            return [
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.65, relativeHeight: 0.7),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.05, relativeWidth: 0.55, relativeHeight: 0.55),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.30, relativeWidth: 0.75, relativeHeight: 0.65),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.05, relativeWidth: 0.60, relativeHeight: 0.45),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.25, relativeWidth: 0.70, relativeHeight: 0.65),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.05, relativeWidth: 0.55, relativeHeight: 0.40),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.30, relativeY: 0.10, relativeWidth: 0.65, relativeHeight: 0.70),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.25, relativeWidth: 0.50, relativeHeight: 0.55),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.70, relativeHeight: 0.65),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.35, relativeWidth: 0.65, relativeHeight: 0.60),
                ]),
            ]
        case 3:
            return [
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.25, relativeWidth: 0.65, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.50, relativeY: 0.60, relativeWidth: 0.40, relativeHeight: 0.30),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.20, relativeWidth: 0.60, relativeHeight: 0.60),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.55, relativeWidth: 0.45, relativeHeight: 0.35),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.75, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.40, relativeWidth: 0.45, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.50, relativeWidth: 0.50, relativeHeight: 0.35),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.75),
                    CompositionBlock(relativeX: 0.35, relativeY: 0.05, relativeWidth: 0.55, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.55, relativeWidth: 0.45, relativeHeight: 0.35),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.15, relativeY: 0.15, relativeWidth: 0.65, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.55, relativeY: 0.50, relativeWidth: 0.35, relativeHeight: 0.40),
                ]),
            ]
        case 4:
            return [
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.55, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.05, relativeWidth: 0.45, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.30, relativeWidth: 0.45, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.35, relativeY: 0.60, relativeWidth: 0.35, relativeHeight: 0.30),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.10, relativeWidth: 0.55, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.35, relativeWidth: 0.45, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.20, relativeY: 0.60, relativeWidth: 0.40, relativeHeight: 0.30),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.20, relativeWidth: 0.50, relativeHeight: 0.45),
                    CompositionBlock(relativeX: 0.10, relativeY: 0.50, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.60, relativeWidth: 0.35, relativeHeight: 0.30),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.10, relativeWidth: 0.55, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.50, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.55, relativeWidth: 0.45, relativeHeight: 0.35),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.20, relativeWidth: 0.60, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.20, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.40, relativeWidth: 0.45, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.65, relativeWidth: 0.35, relativeHeight: 0.25),
                ]),
            ]
        case 5:
            return [
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.50, relativeHeight: 0.45),
                    CompositionBlock(relativeX: 0.20, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.25),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.25, relativeWidth: 0.40, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.10, relativeY: 0.55, relativeWidth: 0.35, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.60, relativeWidth: 0.35, relativeHeight: 0.25),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.10, relativeWidth: 0.50, relativeHeight: 0.45),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.25),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.50, relativeWidth: 0.35, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.35, relativeWidth: 0.40, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.65, relativeWidth: 0.35, relativeHeight: 0.25),
                ]),
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.55, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.35, relativeY: 0.05, relativeWidth: 0.45, relativeHeight: 0.25),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.30, relativeWidth: 0.45, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.50, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.60, relativeWidth: 0.40, relativeHeight: 0.25),
                ]),
            ]
        default:
            return []
        }
    }

    static func pick(for pieceIDs: [UUID]) -> CompositionLayout {
        let available = templates(for: pieceIDs.count)
        guard !available.isEmpty else {
            return CompositionLayout(blocks: [])
        }
        let hash = pieceIDs.map(\.uuidString).joined().hashValue
        let index = abs(hash) % available.count
        return available[index]
    }

    static func sizePriority(for category: GarmentCategory) -> Int {
        switch category.tabGroup {
        case .outerwear: 4
        case .tops: 3
        case .bottoms: 2
        case .shoes: 1
        }
    }
}
