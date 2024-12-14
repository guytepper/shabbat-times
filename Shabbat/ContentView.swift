import SwiftUI

struct ContentView: View {
  @State private var service = ShabbatService()
  
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
                time: "18:32",
                timeZone: "DST",
                timeColor: .orange
              )
              
              Divider()
              
              ShabbatTimeRow(
                title: "Shabbat Ends",
                time: "17:30",
                timeZone: "DST",
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
        Task {
          await loadShabbatTimes()
        }
      }
      
      BottomBar()
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
  //    .environment(\.locale, .init(identifier: "he"))
  //    .environment(\.layoutDirection, .rightToLeft)
}
