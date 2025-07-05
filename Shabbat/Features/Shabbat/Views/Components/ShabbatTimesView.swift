import SwiftUI

struct ShabbatTimesView: View {
  let viewModel: HomeViewModel
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  private var havdalahTitle: String {
    if viewModel.shouldShowHolidayTitle {
      if viewModel.isFastDay {
        return String(localized: "Fast Ends")
      } else {
        return String(localized: "Holiday Ends")
      }
    } else {
      return String(localized: "Shabbat Ends")
    }
  }
  
  var body: some View {
    Group {
      if horizontalSizeClass == .regular {
        timeRow()
      } else {
        timeColumn()
      }
    }
  }
  
  private func timeColumn() -> some View {
    VStack(spacing: 16) {
      ShabbatTimeRow(
        title: String(localized: "Candle Lighting"),
        time: viewModel.candleLighting ?? Date(),
        timeZone: viewModel.timeZone,
        timeColor: .orange
      )
      
      Divider()
      
      ShabbatTimeRow(
        title: havdalahTitle,
        time: viewModel.havdalah ?? Date(),
        timeZone: viewModel.timeZone,
        timeColor: .purple
      )
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor:.tertiarySystemBackground))
        .shadow(color: .black.opacity(0.1), radius: 10)
    )

  }
  
  private func timeRow() -> some View {
    HStack(spacing: 16) {
      ShabbatTimeRow(
        title: String(localized: "Candle Lighting"),
        time: viewModel.candleLighting ?? Date(),
        timeZone: viewModel.timeZone,
        timeColor: .orange
      )
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(uiColor:.tertiarySystemBackground))
          .shadow(color: .black.opacity(0.1), radius: 10)
      )
      
      ShabbatTimeRow(
        title: havdalahTitle,
        time: viewModel.havdalah ?? Date(),
        timeZone: viewModel.timeZone,
        timeColor: .purple
      )
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(uiColor:.tertiarySystemBackground))
          .shadow(color: .black.opacity(0.1), radius: 10)
      )
    }
  }
}
