import SwiftUI

struct ShabbatDateInfo: View {
  @Environment(\.layoutDirection) var layoutDirection
  let nextShabbatDates: String?
  let daysUntilShabbat: String?
  let isShabbat: Bool
  let shouldShowHolidayTitle: Bool
  let holidayTitle: String?
  
  var body: some View {
    VStack(spacing: 6) {
      Text(displayMessage)
        .fontWidth(.expanded)
      
      if let dates = nextShabbatDates {
        Text(dates)
          .font(
            .system(
              layoutDirection == .rightToLeft ? .title2 : .title3,
              design: layoutDirection == .rightToLeft ? .rounded : .serif
            )
            .weight(.bold)
          )
          .multilineTextAlignment(.center)
          .accessibilityLabel(accessibleDateString(from: dates))
      }
      
      if let daysUntil = daysUntilShabbat, !isShabbat {
        Text(daysUntil)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityDescription)
  }
  
  private var displayMessage: String {
    if shouldShowHolidayTitle, let holidayTitle = holidayTitle {
      return holidayTitle.lowercased()
    } else if isShabbat {
      return String(localized: "shabbat shalom")
    } else {
      return String(localized: "next shabbat")
    }
  }
  
  private var accessibilityDescription: String {
    var description = displayMessage
    
    if let dates = nextShabbatDates {
      description += ". \(accessibleDateString(from: dates))"
    }
    
    if let daysUntil = daysUntilShabbat, !isShabbat {
      description += ". \(daysUntil)"
    }
    
    return description
  }
  
  private func accessibleDateString(from dateString: String) -> String {
    // Replace common date range separators with "to" for better VoiceOver pronunciation
    let localizedTo = String(localized: " to ")
    return dateString
      .replacingOccurrences(of: "-", with: localizedTo)
  }
}
