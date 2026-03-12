// KISE/Sources/Services/WeatherService.swift
import Foundation
import WeatherKit
import CoreLocation

@Observable
final class WeatherService {
    private(set) var currentWeather: WeatherSnapshot?
    private(set) var isLoading = false
    private(set) var error: String?

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

            currentWeather = WeatherSnapshot(
                temperature: current.temperature.converted(to: .celsius).value,
                feelsLike: current.apparentTemperature.converted(to: .celsius).value,
                humidity: current.humidity * 100,
                windSpeed: current.wind.speed.converted(to: .kilometersPerHour).value,
                condition: current.condition.rawValue,
                hourlyForecast: Array(hourlyEntries)
            )
        } catch {
            self.error = error.localizedDescription
            // Keep last cached weather if available
        }

        isLoading = false
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
