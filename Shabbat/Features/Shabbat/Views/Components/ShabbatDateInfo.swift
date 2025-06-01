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
      }
      
      if let daysUntil = daysUntilShabbat, !isShabbat {
        Text(daysUntil)
      }
    }
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
}
