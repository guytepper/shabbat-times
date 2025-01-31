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
  let hebrew: String
  var link: String?
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    date = try container.decode(String.self, forKey: .date)
    category = try container.decode(String.self, forKey: .category)
    hebrew = try container.decode(String.self, forKey: .hebrew)
    link = try container.decodeIfPresent(String.self, forKey: .link)
    
    // Set the title property based on app language
    let appLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    let decodedTitle = try container.decode(String.self, forKey: .title)
    title = appLanguage == "he" ? hebrew : decodedTitle
  }
  
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
  @MainActor private(set) var isLoading = false
  private(set) var timeZone: String?
  var candleLighting: ShabbatItem?
  var havdalah: ShabbatItem?
  var parasah: ShabbatItem?
  var error: Error?
  
  @MainActor
  func fetchShabbatTimes(for city: City) async {
    isLoading = true
    
    defer {
      isLoading = false
    }
    
    // Candle-lighting time minutes before sunset
    // For Jerusalem, it's common to light candles 40 minutes before sunset.
    // Otherwise, it's 18 minutes before sunset.
    let beforeSunset = city.name == "Jerusalem" ? 40 : 18
    let latitude = city.coordinate.latitude
    let longitude = city.coordinate.longitude
    
    let urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=pos&latitude=\(latitude)&longitude=\(longitude)&M=on&b=\(beforeSunset)"
    
    guard let url = URL(string: urlString) else {
      error = NSError(domain: "Invalid URL", code: -1)
      return
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(ShabbatResponse.self, from: data)
      
      candleLighting = response.items.first { $0.category == "candles" }
      havdalah = response.items.first { $0.category == "havdalah" }
      parasah = response.items.first { $0.category == "parashat" }
      timeZone = response.location.tzid
      
      error = nil
    } catch {
      self.error = error
      print(error)
    }
  }
}
