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
  
  var formattedDate: Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: date)
  }
}

@Observable
class ShabbatService {
  var candleLighting: ShabbatItem?
  var havdalah: ShabbatItem?
  var error: Error?
  var isLoading = false
  
  func fetchShabbatTimes(latitude: Double, longitude: Double) async {
    isLoading = true
    defer { isLoading = false }
    
//    let urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=pos&latitude=\(latitude)&longitude=\(longitude)&M=on"
    let urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=geoname&geonameid=11524864"
    
    guard let url = URL(string: urlString) else {
      error = NSError(domain: "Invalid URL", code: -1)
      return
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(ShabbatResponse.self, from: data)
      
      candleLighting = response.items.first { $0.category == "candles" }
      havdalah = response.items.first { $0.category == "havdalah" }
      error = nil
    } catch {
      self.error = error
    }
  }
}
