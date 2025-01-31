import Foundation
import SwiftUI

// MARK: - Models
struct ParashaInfo {
  let name: String // English display value
  let hebrewName: String // Hebrew display value
  let url: String
  let description: String
  let hebrewDescription: String
}

// API Response models
private struct SefariaResponse: Codable {
  let calendarItems: [CalendarItem]
  
  enum CodingKeys: String, CodingKey {
    case calendarItems = "calendar_items"
  }
}

private struct CalendarItem: Codable {
  let title: LocalizedText
  let displayValue: LocalizedText
  let url: String
  let description: LocalizedText?
  let category: String
  
  struct LocalizedText: Codable {
    let en: String
    let he: String
  }
}

// MARK: - Service
@Observable
class ParashaService {
  @MainActor private(set) var isLoading = false
  var parasah: ParashaInfo?
  
  private let baseURL = "https://www.sefaria.org/api/calendars"
  
  @MainActor
  func fetchCurrentParasha() async throws {
    isLoading = true
    
    defer {
      isLoading = false
    }
    
    guard let url = URL(string: baseURL) else {
      throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(SefariaResponse.self, from: data)
    
    // Find the Parasha entry
    guard let parashaItem = response.calendarItems.first(where: { item in
      item.title.en == "Parashat Hashavua"
    }) else {
      throw NSError(domain: "ParashaService", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "No parasha found in response"
      ])
    }
    
    self.parasah = ParashaInfo(
      name: parashaItem.displayValue.en,
      hebrewName: parashaItem.displayValue.he,
      url: parashaItem.url,
      description: parashaItem.description?.en ?? "",
      hebrewDescription: parashaItem.description?.he ?? ""
    )
  }
}
