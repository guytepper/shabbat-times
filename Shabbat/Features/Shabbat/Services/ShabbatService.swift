import Foundation
import SwiftUI

struct ShabbatResponse: Codable {
  let items: [ShabbatItem]
  let location: Location
}

struct Location: Codable {
  let title: String
  let city: String
  let tzid: String
  let latitude: Double
  let longitude: Double
}

struct ShabbatItem: Codable, Identifiable {
  let title: String
  let date: String
  let category: String
  
  var id: String {
    "\(category)-\(date)"
  }
  
  func formattedDate(timeZone: String?) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(identifier: timeZone ?? TimeZone.current.identifier)
    return formatter.date(from: date)
  }
}

@Observable
class ShabbatService {
  var candleLighting: ShabbatItem?
  var havdalah: ShabbatItem?
  var timeZone: String?
  var error: Error?
  var isLoading = false
  
  func fetchShabbatTimes(for city: City) async {
    isLoading = true
    // Candle-lighting time minutes before sunset
    // For Jerusalem, it's common to light candles 40 minutes before sunset.
    // Otherwise, it's 18 minutes before sunset.
    let beforeSunset = city.name == "Jerusalem" ? 40 : 18
    let latitude = city.coordinate.latitude
    let longitude = city.coordinate.longitude
    
    let urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=pos&latitude=\(latitude)&longitude=\(longitude)&M=on&b=\(beforeSunset)"
//    let urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=geoname&geonameid=11524864"
    
    guard let url = URL(string: urlString) else {
      error = NSError(domain: "Invalid URL", code: -1)
      return
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(ShabbatResponse.self, from: data)
      
      candleLighting = response.items.first { $0.category == "candles" }
      havdalah = response.items.first { $0.category == "havdalah" }    
      timeZone = response.location.tzid
      
      error = nil
      isLoading = false
    } catch {
      self.error = error
      isLoading = false
    }
  }
}
