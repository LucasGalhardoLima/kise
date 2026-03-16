// KISE/Sources/Services/WeatherService.swift
import Foundation
import WeatherKit
import CoreLocation

@Observable
final class WeatherService {
    private(set) var currentWeather: WeatherSnapshot?
    private(set) var isLoading = false
    private(set) var error: String?
    /// iOS 26+: significant weather change alert (e.g., "Tomorrow will be 12°C colder")
    private(set) var significantChangeNote: String?

    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = LocationManager()

    func fetchWeather() async {
        guard let location = await locationManager.currentLocation() else {
            error = "Location unavailable"
            return
        }

        isLoading = true
        error = nil

        do {
            let weather = try await weatherService.weather(
                for: location,
                including: .current, .hourly
            )

            let current = weather.0
            let hourly = weather.1

            let hourlyEntries = hourly.prefix(12).map { entry in
                HourlyEntry(
                    hour: Calendar.current.component(.hour, from: entry.date),
                    temperature: entry.temperature.converted(to: .celsius).value,
                    condition: entry.condition.rawValue
                )
            }

            let cityName = await resolveCity(from: location)

            currentWeather = WeatherSnapshot(
                temperature: current.temperature.converted(to: .celsius).value,
                feelsLike: current.apparentTemperature.converted(to: .celsius).value,
                humidity: current.humidity * 100,
                windSpeed: current.wind.speed.converted(to: .kilometersPerHour).value,
                condition: current.condition.rawValue,
                hourlyForecast: Array(hourlyEntries),
                cityName: cityName
            )

            // iOS 26+: Check for significant temperature changes tomorrow
            await fetchSignificantChanges(location: location)
        } catch {
            self.error = error.localizedDescription
            // Keep last cached weather if available
        }

        isLoading = false
    }

    private func resolveCity(from location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        return placemarks?.first?.locality
    }

    private func fetchSignificantChanges(location: CLLocation) async {
        if #available(iOS 26, *) {
            do {
                let daily = try await weatherService.weather(
                    for: location,
                    including: .daily
                )
                // Compare today and tomorrow
                let forecasts = Array(daily.prefix(2))
                if forecasts.count == 2 {
                    let todayHigh = forecasts[0].highTemperature.converted(to: .celsius).value
                    let tomorrowHigh = forecasts[1].highTemperature.converted(to: .celsius).value
                    let delta = tomorrowHigh - todayHigh

                    if abs(delta) >= 8 {
                        if delta < 0 {
                            significantChangeNote = "Tomorrow will be \(Int(abs(delta)))°C colder — plan a warmer outfit."
                        } else {
                            significantChangeNote = "Tomorrow will be \(Int(delta))°C warmer — lighter layers ahead."
                        }
                    } else {
                        significantChangeNote = nil
                    }
                }
            } catch {
                // Non-critical — silently skip
            }
        }
    }
}

// MARK: - Location Manager

final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Wait briefly for authorization
            try? await Task.sleep(for: .seconds(1))
        }

        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
