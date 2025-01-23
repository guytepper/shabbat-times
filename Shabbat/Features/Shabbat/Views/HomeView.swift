import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
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
            .padding(.bottom, 4)
          
          Text("🥖")
            .font(.system(size: 120))
            .rotationEffect(.degrees(-45))
            .padding(.bottom, 16)
          
          VStack(spacing: 6) {
            Text("next shabbat")
              .fontWidth(.expanded)
            
            Text("24-25th January, 2024")
              .font(.system(.title3, design: .serif).weight(.bold))
            
            Text("in 3 days")
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
      
      BottomBar(
        cityName: cityManager?.getCurrentCity()?.name ?? "Select City"
      ) { city in
        cityManager?.saveCity(
          name: city.name,
          country: city.country,
          coordinate: city.coordinate
        )
        Task {
          await loadShabbatTimes()
        }
      }
      .background(Color.black.opacity(0.3))
    }
    .background(gradientBackground)
  }
  
  var gradientBackground: some ShapeStyle {
    LinearGradient(
      colors: [
        .hsl(h: 0, s: 0, l: 100),
        .hsl(h: 48, s: 55, l: 84)
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }
  
  private func loadShabbatTimes() async {
    if let city = cityManager?.getCurrentCity() {
      print("Loading Shabbat times for \(city.name)")
      await service.fetchShabbatTimes(for: city)
    }
  }
  
  private func formatCurrentTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm (zzz)"
    return formatter.string(from: Date())
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

