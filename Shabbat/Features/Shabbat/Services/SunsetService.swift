import CoreLocation
import Foundation
import WeatherKit

@Observable
class SunsetService {
  @MainActor private(set) var isLoading = false
  private(set) var sunset: Date?
  private(set) var error: Error?

  private let weatherService = WeatherService.shared

  @MainActor
  func fetchSunset(
    for city: City,
    referenceDate: Date?,
    timeZoneIdentifier: String?
  ) async {
    isLoading = true

    defer { isLoading = false }

    do {
      let location = CLLocation(latitude: city.latitude, longitude: city.longitude)
      let dailyWeather = try await weatherService.weather(for: location, including: .daily)

      var calendar = Calendar.current
      if let identifier = timeZoneIdentifier, let timeZone = TimeZone(identifier: identifier) {
        calendar.timeZone = timeZone
      }

      let targetDate = referenceDate ?? Date()
      let targetDay = calendar.startOfDay(for: targetDate)

      if let matchingDay = dailyWeather.forecast.first(where: { day in
        calendar.isDate(day.date, inSameDayAs: targetDay)
      }) {
        sunset = matchingDay.sun.sunset
        error = nil
      } else {
        sunset = nil
        error = nil
      }
    } catch {
      sunset = nil
      self.error = error
    }
  }

  @MainActor
  func reset() {
    sunset = nil
    error = nil
  }
}
