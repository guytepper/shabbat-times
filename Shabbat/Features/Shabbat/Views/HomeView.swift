import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.layoutDirection) var layoutDirection
  @Environment(\.modelContext) private var modelContext
  @State private var service = ShabbatService()
  @State private var cityManager: CityManager?
  
  var cityName: String{
    cityManager?.getCurrentCity()?.name ?? ""
  }
  
  var candleLighting: Date? {
    return service.candleLighting?.formattedDate(timeZone: service.timeZone)
  }
  
  var havdalah: Date? {
    service.havdalah?.formattedDate(timeZone: service.timeZone)
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .center) {
          Button(action: {
            try? modelContext.delete(model: City.self)
          }) {
            Text(cityName)
              .font(.title3)
              .fontWeight(.bold)
              .foregroundStyle(.blue)
          }
          
          Text("🥖")
            .font(.system(size: 120))
            .rotationEffect(.degrees(layoutDirection == .rightToLeft ? 45 : -45))
            .padding(.top, 12)
            .padding(.bottom, 24)
          
          VStack(spacing: 6) {
            Text("next shabbat")
              .fontWidth(.expanded)
            
            if let dates = nextShabbatDates {
              Text(dates)
                .font(
                  .system(
                    layoutDirection == .rightToLeft ? .title2 : .title3,
                    design: .serif
                  )
                  .weight(.bold)
                )
            }
            
            if let daysUntil = daysUntilShabbat {
              Text(daysUntil)
            }
          }
          .padding(.bottom, 24)
          
          
          if service.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let error = service.error {
            ErrorMessage(error: error, onRetry: loadShabbatTimes)
              .frame(maxWidth: .infinity)
              .padding()
          } else  {
            VStack(spacing: 16) {
              ShabbatTimeRow(
                title: ShabbatTimeType.candleLighting.title,
                time: candleLighting ?? Date(),
                timeZone: TimeZone(identifier: service.timeZone ?? TimeZone.current.identifier) ?? .current,
                timeColor: .orange
              )
              
              Divider()
              
              ShabbatTimeRow(
                title: ShabbatTimeType.havdalah.title,
                time: havdalah ?? Date(),
                timeZone: TimeZone(identifier: service.timeZone ?? TimeZone.current.identifier) ?? .current,
                timeColor: .purple
              )
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
            )
            .padding(.bottom)
          }
        }
        .padding()
      }
      .onAppear {
        // Initialize cityManager when the view appears
        if cityManager == nil {
          cityManager = CityManager(modelContext: modelContext)
        }
        Task {
          await loadShabbatTimes()
        }
      }
      .background(gradientBackground)
    }
  }
  
  var gradientBackground: some ShapeStyle {
    return LinearGradient(
      colors: colorScheme == .dark ? [
        .hsl(h: 48, s: 0, l: 2),    // Very dark gray
        .hsl(h: 48, s: 30, l: 10)   // Dark warm brown
      ] : [
        .hsl(h: 0, s: 0, l: 100),   // White
        .hsl(h: 48, s: 55, l: 84)   // Light warm beige
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }
  
  private func loadShabbatTimes() async {
    
    if let city = cityManager?.getCurrentCity() {
      await try service.fetchShabbatTimes(for: city)
    }
  }

  private var nextShabbatDates: String? {
    let timeZone = service.timeZone ?? TimeZone.current.identifier
    guard let candleLighting = service.candleLighting?.formattedDate(timeZone: timeZone),
          let havdalah = service.havdalah?.formattedDate(timeZone: timeZone) else { return nil }

    let startDate = candleLighting
    let endDate = havdalah
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d"
    
    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM"
    
    let startDay = dateFormatter.string(from: startDate)
    let endDay = dateFormatter.string(from: endDate)
    
    // Handle cases where the start & end dates are on different months
    let startMonth = monthFormatter.string(from: startDate)
    let endMonth = monthFormatter.string(from: endDate)
    
    if startMonth == endMonth {
        return "\(startDay) - \(endDay) \(startMonth)"
    } else {
        return "\(startDay) \(startMonth) - \(endDay) \(endMonth)"
    }
  }

  private var daysUntilShabbat: String? {
    guard let candleLighting = service.candleLighting?.formattedDate(timeZone: TimeZone.current.abbreviation() ?? "UTC") else { return nil }
    
    let calendar = Calendar.current
    let now = Date()
    
    let components = calendar.dateComponents([.day], from: now, to: candleLighting)
    guard let days = components.day else { return nil }
    
    if days == 0 {
      return String(localized: "today")
    } else if days == 1 {
      return String(localized: "tomorrow")
    } else {
      return String(localized: "in \(days) days")
    }
  }
}

#Preview {
  let container = try! ModelContainer(for: City.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
  
  // Create and save a sample city
  let sampleCity = City(name: "Jerusalem", country: "Israel", coordinate: CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137))
//  let usaCity = City(name: "Arcata, CA", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 40.86731, longitude: 124.08522))
  try! container.mainContext.insert(sampleCity)
  
  return HomeView()
    .modelContainer(container)
}

