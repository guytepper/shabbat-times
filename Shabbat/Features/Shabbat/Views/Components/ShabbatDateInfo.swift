import SwiftUI

struct ShabbatDateInfo: View {
  @Environment(\.layoutDirection) var layoutDirection
  let nextShabbatDates: String?
  let daysUntilShabbat: String?
  let isShabbat: Bool
  
  var body: some View {
    VStack(spacing: 6) {
      Text(isShabbat ? "shabbat shalom" : "next shabbat")
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
}
