import SwiftUI

struct ContentView: View {
  @State private var service = ShabbatService()
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .center) {
            Text("קדימה-צורן")
              .foregroundStyle(.blue)
              .font(.largeTitle)
              .fontDesign(.rounded)
              .bold()
            
            Spacer()
            
            HStack(alignment: .center, spacing: 8) {
              Image(systemName: "gear")
                .font(.title2)
            }
          }
          
//          Text("Local Time: \(formatCurrentTime())")
//            .font(.headline)
        }
        .padding(.bottom, 12)
        
        if service.isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = service.error {
          VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
              .font(.title)
              .foregroundColor(.orange)
            Text("Error loading times")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.subheadline)
              .foregroundColor(.secondary)
            Button("Retry") {
              Task {
                await loadShabbatTimes()
              }
            }
            .buttonStyle(.bordered)
          }
          .frame(maxWidth: .infinity)
          .padding()
        } else if let candleLighting = service.candleLighting,
                  let havdalah = service.havdalah {
          VStack(spacing: 16) {
            TimeCard(
              timeType: .candleLighting,
              date: candleLighting.formattedDate ?? Date()
            )
            
            TimeCard(
              timeType: .havdalah,
              date: havdalah.formattedDate ?? Date()
            )
          }
          .padding(.bottom)
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text("Parashat Mishpatim")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text("Mishpatim (“Laws”) recounts a series of God’s laws that Moses gives to the Israelites. These include laws about treatment of slaves, damages, loans, returning lost property, the Sabbath, the sabbatical year, holidays, and destroying idolatry. The portion ends as Moses ascends Mount Sinai for 40 days.")
        }
      }
      .padding()
    }
    .onAppear {
      Task {
        await loadShabbatTimes()
      }
    }
  }
  
  private func loadShabbatTimes() async {
    // Example coordinates for Los Angeles
    await service.fetchShabbatTimes(latitude: 34.0522, longitude: -118.2437)
  }
  
  private func formatCurrentTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm (zzz)"
    return formatter.string(from: Date())
  }
}

#Preview {
  ContentView()
    .environment(\.locale, .init(identifier: "he"))
    .environment(\.layoutDirection, .rightToLeft)
}
