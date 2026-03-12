// KISE/Sources/Models/WeatherSnapshot.swift
import Foundation

struct HourlyEntry: Codable, Equatable {
    let hour: Int
    let temperature: Double
    let condition: String
}

struct WeatherSnapshot: Codable, Equatable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Double
    let windSpeed: Double
    let condition: String
    let hourlyForecast: [HourlyEntry]

    var hasSignificantTransition: Bool {
        guard let minTemp = hourlyForecast.map(\.temperature).min(),
              let maxTemp = hourlyForecast.map(\.temperature).max() else {
            return false
        }
        return (maxTemp - minTemp) > 10
    }
}
