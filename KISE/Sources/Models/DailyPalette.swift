import Foundation

struct DailyPalette: Codable {
    let city: String
    let temperature: Int
    let condition: String
    let paletteName: String
    let description: String
    let colors: [String]
}
