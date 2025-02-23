import SwiftUI

struct ShabbatTimesView: View {
  let viewModel: HomeViewModel
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
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
        title: ShabbatTimeType.candleLighting.title,
        time: viewModel.candleLighting ?? Date(),
        timeZone: viewModel.timeZone,
        timeColor: .orange
      )
      
      Divider()
      
      ShabbatTimeRow(
        title: ShabbatTimeType.havdalah.title,
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
        title: ShabbatTimeType.candleLighting.title,
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
        title: ShabbatTimeType.havdalah.title,
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
