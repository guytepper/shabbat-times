import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var service = ShabbatService()
  @State private var cityManager: CityManager?
  
  var cityName: String{
    cityManager?.getCurrentCity()?.name ?? ""
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .center) {
          Text(cityName)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.blue)
          
          Text("🥖")
            .font(.system(size: 120))
            .rotationEffect(.degrees(-45))
            .padding(.top, 12)
            .padding(.bottom, 24)
          
          VStack(spacing: 6) {
            Text("next shabbat")
              .fontWidth(.expanded)
            
            if let dates = nextShabbatDates {
              Text(dates)
                .font(.system(.title3, design: .serif).weight(.bold))
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
          } else if let candleLighting = service.candleLighting,
                    let havdalah = service.havdalah {
            VStack(spacing: 16) {
              ShabbatTimeRow(
                title: "Candle Lighting",
                time: candleLighting.formattedDate?
                  .formatted(date: .omitted, time: .shortened) ?? "N/A",
                timeZone: TimeZone.current.abbreviation() ?? "Local",
                timeColor: .orange
              ).onTapGesture {
                try? modelContext.delete(model: City.self)
              }
              
              Divider()
              
              ShabbatTimeRow(
                title: "Shabbat Ends",
                time: havdalah.formattedDate?
                  .formatted(date: .omitted, time: .shortened) ?? "N/A",
                timeZone: TimeZone.current.abbreviation() ?? "Local",
                timeColor: .purple
              )
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
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
      
//      BottomBar(
//        cityName: cityManager?.getCurrentCity()?.name ?? "Select City"
//      ) { city in
//        cityManager?.saveCity(
//          name: city.name,
//          country: city.country,
//          coordinate: city.coordinate
//        )
//        Task {
//          await loadShabbatTimes()
//        }
//      }
//      .background(Color.black.opacity(0.3))
    }
    .background(gradientBackground)
  }
  
  var gradientBackground: some ShapeStyle {
    return LinearGradient(
      colors: colorScheme == .dark ? [
        .hsl(h: 0, s: 0, l: 2),    // Very dark gray
        .hsl(h: 0, s: 0, l: 0)   // Dark warm brown
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
      await service.fetchShabbatTimes(for: city)
    }
  }
  
  private func formatCurrentTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm (zzz)"
    return formatter.string(from: Date())
  }

  private var nextShabbatDates: String? {
    guard let candleLighting = service.candleLighting?.formattedDate,
          let havdalah = service.havdalah?.formattedDate else { return nil }
    
    let calendar = Calendar.current
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
    guard let candleLighting = service.candleLighting?.formattedDate else { return nil }
    
    let calendar = Calendar.current
    let now = Date()
    
    let components = calendar.dateComponents([.day], from: now, to: candleLighting)
    guard let days = components.day else { return nil }
    
    if days == 0 {
      return "today"
    } else if days == 1 {
      return "tomorrow"
    } else {
      return "in \(days) days"
    }
  }
}

#Preview {
  let container = try! ModelContainer(for: City.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
  
  // Create and save a sample city
  let sampleCity = City(name: "Jerusalem", country: "Israel", coordinate: CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137))
  try! container.mainContext.insert(sampleCity)
  
  return HomeView()
    .modelContainer(container)
}

