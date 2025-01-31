import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.layoutDirection) var layoutDirection
  @Environment(\.modelContext) private var modelContext
  
  @State private var shabbatService = ShabbatService()
  @State private var parashaService = ParashaService()
  
  @State private var cityManager: CityManager?
  @State private var showLocationPicker = false
  @State private var showParashaModal = false
  
  var cityName: String{
    cityManager?.getCurrentCity()?.name ?? ""
  }
  
  var candleLighting: Date? {
    return shabbatService.candleLighting?.formattedDate(timeZone: shabbatService.timeZone)
  }
  
  var havdalah: Date? {
    shabbatService.havdalah?.formattedDate(timeZone: shabbatService.timeZone)
  }
  
  var parasahName: String {
    if let parasah = shabbatService.parasah {
      return layoutDirection == .rightToLeft ? parasah.hebrew : parasah.title
    }
    
    return ""
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .center) {
          Button(action: {
            showLocationPicker = true
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
          
          
          if shabbatService.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let error = shabbatService.error {
            ErrorMessage(error: error, onRetry: loadShabbatTimes)
              .frame(maxWidth: .infinity)
              .padding()
          } else  {
            VStack(spacing: 16) {
              ShabbatTimeRow(
                title: ShabbatTimeType.candleLighting.title,
                time: candleLighting ?? Date(),
                timeZone: TimeZone(identifier: shabbatService.timeZone ?? TimeZone.current.identifier) ?? .current,
                timeColor: .orange
              )
              
              Divider()
              
              ShabbatTimeRow(
                title: ShabbatTimeType.havdalah.title,
                time: havdalah ?? Date(),
                timeZone: TimeZone(identifier: shabbatService.timeZone ?? TimeZone.current.identifier) ?? .current,
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
            
            Button {
              showParashaModal = true
            } label: {
              HStack {
                Spacer()
                Text(parasahName)
                  .font(layoutDirection == .rightToLeft ? .title2 : .title3)
                  .fontDesign(.serif)
                  .bold()
                  .foregroundStyle(Color(uiColor: .label))
                Spacer()
              }
              .padding(26)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(.amber)
              )
            }
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
          try await parashaService.fetchCurrentParasha()
        }
      }
      .background(gradientBackground)
      .fullScreenCover(isPresented: $showLocationPicker) {
        LocationSelectionView { city in
          try? modelContext.delete(model: City.self)
          
          cityManager?.saveCity(
            name: city.name,
            country: city.country,
            coordinate: city.coordinate
          )
          
          Task {
            await loadShabbatTimes()
          }
        }
      }
      .sheet(isPresented: $showParashaModal) {
        NavigationView {
          ParashaView(parasha: parashaService.parasah, isLoading: parashaService.isLoading)
            .navigationTitle("Weekly Torah Portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  showParashaModal = false
                }
              }
            }
        }
      }
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
      await shabbatService.fetchShabbatTimes(for: city)
    }
  }
  
  private var nextShabbatDates: String? {
    let timeZone = shabbatService.timeZone ?? TimeZone.current.identifier

    guard let candleLighting = shabbatService.candleLighting?.formattedDate(timeZone: timeZone),
          let havdalah = shabbatService.havdalah?.formattedDate(timeZone: timeZone) else { return nil }
    
    let startDate = candleLighting
    let endDate = havdalah
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d"
    dateFormatter.timeZone = TimeZone(identifier: timeZone) ?? .current
    
    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM"
    monthFormatter.timeZone = TimeZone(identifier: timeZone) ?? .current
    
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
    guard let candleLighting = shabbatService.candleLighting?.formattedDate(timeZone: TimeZone.current.abbreviation() ?? "UTC") else { return nil }
    
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
