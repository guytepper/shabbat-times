import SwiftUI
import SwiftData

struct WelcomeView: View {
  @Environment(\.colorScheme) private var colorScheme
  @StateObject private var locationManager = LocationManager()
  @State private var showLocationPicker = false
  
  @Environment(\.modelContext) private var modelContext
  private var cityManager: CityManager {
    CityManager(modelContext: modelContext)
  }
  
  var body: some View {
    VStack(spacing: 16) {
      Spacer()
      
      EmojisView()
      
      Spacer()
      
      VStack(spacing: 12) {
        Text("Shabbat Shalom!")
          .font(.largeTitle)
          .fontWeight(.bold)
          .fontWidth(Font.Width(0.05))
          .shadow(color: colorScheme == .dark ? .white :  .black.opacity(0.2), radius: 8)

        
        Text("Find Shabbat times for your location.")
          .font(.body)
          .multilineTextAlignment(.center)
          .padding(.bottom, 12)
        
        selectCityButton
      }
      .padding()
    }
    .padding(.bottom, 32)
  }
  
  private var selectCityButton: some View {
    Button {
      showLocationPicker = true
    } label: {
      HStack {
        Text("Select City")
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(12)
    }
    .fullScreenCover(isPresented: $showLocationPicker) {
      LocationSelectionView { city in
        cityManager.saveCity(
          name: city.name,
          country: city.country,
          coordinate: city.coordinate
        )
      }
    }
    
  }
}

#Preview {
  WelcomeView()
    .modelContainer(for: City.self, inMemory: true)
    .background(Color.gradientBackground(for: .light))
}


struct EmojisView: View {
  @State private var animatedEmojis = Array(repeating: false, count: 5)
  
  let emojis = ["✨", "🕯️", "🍷", "📖", "🕍"]
  let radius: CGFloat = 90
  
  var body: some View {
    ZStack {
      ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
        Text(emoji)
          .shadow(color: .black.opacity(0.1), radius: 6)
          .font(.system(size: 58))
          .offset(
            x: radius * cos(2 * .pi * Double(index) / Double(emojis.count)),
            y: radius * sin(2 * .pi * Double(index) / Double(emojis.count))
          )
          .scaleEffect(animatedEmojis[index] ? 1 : 0)
          .animation(
            .spring(response: 0.6, dampingFraction: 0.6)
            .delay(Double(index) * 0.5),
            value: animatedEmojis[index]
          )
      }
    }
    .frame(height: radius * 2.5) // Give enough space for the circle
    .onAppear {
      for index in animatedEmojis.indices {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          animatedEmojis[index] = true
        }
      }
    }
  }
}

