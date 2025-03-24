import WidgetKit
import SwiftUI
import SwiftData

let exampleEntry = ShabbatEntry(
  date: .now,
  candleLightingDate: .now,
  havdalahDate: .now.addingTimeInterval(24 * 60 * 60),
  city: City(name: "Jerusalem", country: "Israel", coordinate: .init(latitude: 31.7683, longitude: 35.2137)),
  timeZone: TimeZone.current.identifier
)


struct Provider: TimelineProvider {
  typealias Entry = ShabbatEntry

  @Environment(\.modelContext) private var modelContext
  let shabbatService = ShabbatService()
  
  
  func placeholder(in context: Context) -> Entry {
    exampleEntry
  }
  
  func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
    completion(exampleEntry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    Task {
      // Get current city using a fetch descriptor
      let descriptor = FetchDescriptor<City>()
      let cities = try? modelContext.fetch(descriptor)
      let city = cities?.first ?? City(
        name: "New York",
        country: "USA",
        coordinate: .init(latitude: 40.7128, longitude: -74.0060)
      )
      
      await shabbatService.fetchShabbatTimes(for: city)
      
      if let candleLighting = shabbatService.candleLighting?.formattedDate(timeZone: shabbatService.timeZone),
         let havdalah = shabbatService.havdalah?.formattedDate(timeZone: shabbatService.timeZone) {
        
        let entry = ShabbatEntry(
          date: Date(),
          candleLightingDate: candleLighting,
          havdalahDate: havdalah,
          city: city,
          timeZone: shabbatService.timeZone ?? TimeZone.current.identifier
        )
        
        let timeline = Timeline(
          entries: [entry],
          policy: .after(havdalah)
        )
        
        completion(timeline)
      } else {
        completion(Timeline(entries: [placeholder(in: context)], policy: .atEnd))
      }
    }
  }
  
  
  //    func relevances() async -> WidgetRelevances<Void> {
  //        // Generate a list containing the contexts this widget is relevant in.
  //    }
}

struct ShabbatEntry: TimelineEntry {
  let date: Date
  let candleLightingDate: Date
  let havdalahDate: Date
  let city: City
  let timeZone: String
}

struct ShabbatWidgetEntryView : View {
  var entry: Provider.Entry
  
  var countdownText: String {
    let calendar = Calendar.current
    let now = Date()
    let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: entry.candleLightingDate)).day ?? 0
    
    return daysDifference == 0 ? "today" :
           daysDifference == 1 ? "tomorrow" :
           "\(daysDifference) days left"
  }
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 8) {
        VStack(alignment: .leading, spacing: 2) {
          Text("next shabbat")
            .font(.footnote)
            .fontWeight(.light)
            .foregroundColor(.black)
          
          Text(countdownText)
            .bold()
            .font(.subheadline)
            .fontWeight(.light)
            .foregroundColor(.black)
        }
        .fontDesign(.rounded)
        
        
        Spacer()
        
        VStack(alignment: .leading) {
          Text(entry.date, style: .time)
            .font(.title)
            .bold()
            .foregroundColor(Color.orange)
          
          Text("Mar 24 ⋅ New York")
            .font(.caption)
        }
        .fontDesign(.rounded)
      }
      
      Spacer()
    }
  }
}

struct ShabbatWidget: Widget {
  let kind: String = "ShabbatWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      ShabbatWidgetEntryView(entry: entry)
        .containerBackground(
          LinearGradient(
            gradient: Gradient(colors: [Color.white, Color.yellow.opacity(0.2)]),
            startPoint: .top,
            endPoint: .bottom
          ),
          for: .widget
        )
        .modelContainer(for: [City.self, Settings.self])
    }
    .configurationDisplayName("Candle lightning")
    .description("Displays the candle lightning times.")
  }
}

#Preview(as: .systemSmall) {
  ShabbatWidget()
} timeline: {
  ShabbatEntry(
    date: .now,
    candleLightingDate: .now,
    havdalahDate: .now.addingTimeInterval(24 * 60 * 60),
    city: City(
      name: "New York",
      country: "USA",
      coordinate: .init(latitude: 40.7128, longitude: -74.0060)
    ),
    timeZone: TimeZone.current.identifier
  )
}
