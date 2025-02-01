import SwiftUI

struct ShabbatDateInfo: View {
  @Environment(\.layoutDirection) var layoutDirection
  let nextShabbatDates: String?
  let daysUntilShabbat: String?
  
  var body: some View {
    VStack(spacing: 6) {
      Text("next shabbat")
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
      
      if let daysUntil = daysUntilShabbat {
        Text(daysUntil)
      }
    }
  }
}
