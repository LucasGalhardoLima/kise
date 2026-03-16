// KISE/Tests/Services/WeatherServiceTests.swift
import Testing
@testable import KISE

struct WeatherServiceTests {
    @Test func weatherServiceInitialState() {
        let service = WeatherService()
        #expect(service.currentWeather == nil)
        #expect(service.isLoading == false)
        #expect(service.error == nil)
    }

    @Test func weatherSnapshotTransitionDetection() {
        let noTransition = WeatherSnapshot(
            temperature: 22,
            feelsLike: 20,
            humidity: 65,
            windSpeed: 12,
            condition: "clear",
            hourlyForecast: [
                HourlyEntry(hour: 7, temperature: 20, condition: "clear"),
                HourlyEntry(hour: 12, temperature: 25, condition: "sunny"),
            ],
            cityName: nil
        )
        #expect(noTransition.hasSignificantTransition == false)

        let withTransition = WeatherSnapshot(
            temperature: 14,
            feelsLike: 12,
            humidity: 70,
            windSpeed: 15,
            condition: "cloudy",
            hourlyForecast: [
                HourlyEntry(hour: 7, temperature: 14, condition: "cloudy"),
                HourlyEntry(hour: 14, temperature: 26, condition: "sunny"),
            ],
            cityName: nil
        )
        #expect(withTransition.hasSignificantTransition == true)
    }
}
