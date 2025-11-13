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

      if viewModel.shouldShowSunsetTime {
        SunsetTimeRow(
          time: viewModel.sunset,
          timeZone: viewModel.timeZone,
          isLoading: viewModel.isSunsetLoading
        )

        Divider()
      }

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
      timeCard {
        ShabbatTimeRow(
          title: String(localized: "Candle Lighting"),
          time: viewModel.candleLighting ?? Date(),
          timeZone: viewModel.timeZone,
          timeColor: .orange
        )
      }

      if viewModel.shouldShowSunsetTime {
        timeCard {
          SunsetTimeRow(
            time: viewModel.sunset,
            timeZone: viewModel.timeZone,
            isLoading: viewModel.isSunsetLoading
          )
        }
      }

      timeCard {
        ShabbatTimeRow(
          title: havdalahTitle,
          time: viewModel.havdalah ?? Date(),
          timeZone: viewModel.timeZone,
          timeColor: .purple
        )
      }
    }
  }

  @ViewBuilder
  private func timeCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(uiColor:.tertiarySystemBackground))
          .shadow(color: .black.opacity(0.1), radius: 10)
      )
  }
}

private struct SunsetTimeRow: View {
  let time: Date?
  let timeZone: TimeZone
  let isLoading: Bool

  private var formattedTime: String? {
    guard let time else { return nil }

    let formatter = DateFormatter()

    let currentLocale = Locale.current
    let isHebrew = currentLocale.language.languageCode?.identifier == "he"

    if isHebrew {
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "HH:mm"
    } else {
      formatter.locale = currentLocale
      formatter.dateFormat = "h:mm a"
    }

    formatter.timeZone = timeZone
    return formatter.string(from: time)
  }

  private var accessibleTimeDescription: String? {
    guard let time else { return nil }
    let formatter = DateFormatter()
    formatter.timeZone = timeZone
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: time)
  }

  var body: some View {
    HStack(alignment: .center) {
      Text(String(localized: "Sunset"))
        .font(.headline)

      Spacer()

      VStack(alignment: .trailing, spacing: 2) {
        if isLoading {
          ProgressView()
            .progressViewStyle(.circular)
        } else if let formattedTime {
          Text(formattedTime)
            .foregroundColor(.yellow)
            .font(.title2)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
        } else {
          Text(String(localized: "Unavailable"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 16)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(String(localized: "Sunset"))
    .accessibilityValue(accessibilityValue)
    .accessibilityAddTraits(.isStaticText)
  }

  private var accessibilityValue: String {
    if isLoading {
      return String(localized: "Loading")
    }

    if let accessibleTimeDescription {
      return accessibleTimeDescription
    }

    return String(localized: "Unavailable")
  }
}
