import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var service = ShabbatService()
  @State private var cityManager: CityManager?
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .center) {
          Text("✨")
            .font(.largeTitle)
            .padding(.bottom, 62)
          
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
                .fill(Color.hsl(h: 0, s: 0, l: 0))
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
        .hsl(h: 220, s: 65, l: 10),
        .hsl(h: 220, s: 55, l: 60)
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
  HomeView()
    .modelContainer(for: City.self, inMemory: true)
  //    .environment(\.locale, .init(identifier: "he"))
  //    .environment(\.layoutDirection, .rightToLeft)
}

