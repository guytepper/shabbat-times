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
  
  @Binding var tabSelection: Int
  
  var body: some View {
    VStack(spacing: 16) {
      Spacer()
      
      EmojisView()
      
      Spacer()
      
      VStack(spacing: 12) {
        VStack(spacing: 6) {
          Text("Welcome to")
            .foregroundStyle(.brown)
            .fontWeight(.semibold)
            .font(.subheadline)
          
          Text("Shabbat Times")
            .font(.largeTitle)
            .fontWeight(.bold)
            .fontWidth(Font.Width(0.05))
            .shadow(color: colorScheme == .dark ? .white :  .black.opacity(0.2), radius: 8)
        }
        .padding(.bottom, 12)
        
        Text("Select a city to get local shabbat times for.")
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
      withAnimation {
        showLocationPicker = true
      }
    } label: {
      HStack {
        Text("Select City")
      }
      .frame(maxWidth: 400)
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
        
        // Delay next page navigation for smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          withAnimation {
            tabSelection += 1
          }
        }
      }
    }
    
  }
}

#Preview {
  WelcomeView(tabSelection: .constant(0))
    .modelContainer(for: City.self, inMemory: true)
    .background(Color.gradientBackground(for: .light))
}


struct EmojisView: View {
  @State private var candlesVisible = false
  @State private var starsVisible = false
  @State private var chalahVisible = false
  @State private var sparkleAnimation = false
  
  var body: some View {
    GeometryReader { geometry in
      let offsetMultiplier = geometry.size.width > 600 ? 2.4 : 1.0
      
      ZStack {
        Circle()
          .fill(
            RadialGradient(
              gradient: Gradient(colors: [
                Color.blue.opacity(0.15),
                Color.purple.opacity(0.1),
                Color.clear
              ]),
              center: .center,
              startRadius: 0,
              endRadius: 150 * offsetMultiplier
            )
          )
          .frame(width: 300 * offsetMultiplier, height: 300 * offsetMultiplier)
          .scaleEffect(sparkleAnimation ? 1.2 : 0.8)
          .animation(
            .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
            value: sparkleAnimation
          )
        
        Image("stars")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 80 * offsetMultiplier, height: 80 * offsetMultiplier)
          .rotationEffect(.degrees(sparkleAnimation ? 360 : 0))
          .offset(
            x: -120 * offsetMultiplier + (sparkleAnimation ? sin(Date().timeIntervalSince1970) * 8 : 0),
            y: -80 * offsetMultiplier + (sparkleAnimation ? cos(Date().timeIntervalSince1970) * 6 : 0)
          )
          .scaleEffect(starsVisible ? 1.0 : 0.3)
          .opacity(starsVisible ? 0.8 : 0.0)
          .animation(
            .spring(response: 1.0, dampingFraction: 0.7)
            .delay(0.8),
            value: starsVisible
          )
          .animation(
            .linear(duration: 12).repeatForever(autoreverses: false),
            value: sparkleAnimation
          )
        
        Image("candles")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 160 * offsetMultiplier)
          .shadow(color: .orange.opacity(0.3), radius: 15)
          .scaleEffect(candlesVisible ? 1.1 : 0.5)
          .opacity(candlesVisible ? 1.0 : 0.0)
          .animation(
            .spring(response: 1.5, dampingFraction: 0.6)
            .delay(0.4),
            value: candlesVisible
          )
        
        Image("chalah")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 70 * offsetMultiplier, height: 70 * offsetMultiplier)
          .offset(x: 130 * offsetMultiplier, y: 60 * offsetMultiplier)
          .scaleEffect(chalahVisible ? 1.0 : 0.3)
          .opacity(chalahVisible ? 0.75 : 0.0)
          .rotationEffect(.degrees(chalahVisible ? 0 : -45))
          .animation(
            .spring(response: 1.2, dampingFraction: 0.8)
            .delay(1.2),
            value: chalahVisible
          )
        
        Image("david_star")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 65 * offsetMultiplier, height: 65 * offsetMultiplier)
          .offset(x: -130 * offsetMultiplier, y: 70 * offsetMultiplier)
          .scaleEffect(starsVisible ? 1.0 : 0.2)
          .opacity(starsVisible ? 0.6 : 0.0)
          .animation(
            .spring(response: 1.8, dampingFraction: 0.5)
            .delay(1.6),
            value: starsVisible
          )
        
        Image("synagouge")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 70 * offsetMultiplier, height: 70 * offsetMultiplier)
          .offset(x: 110 * offsetMultiplier, y: -90 * offsetMultiplier)
          .scaleEffect(chalahVisible ? 1.0 : 0.1)
          .opacity(chalahVisible ? 0.75 : 0.0)
          .animation(
            .spring(response: 2.0, dampingFraction: 0.7)
            .delay(2.0),
            value: chalahVisible
          )
      }
      .frame(width: geometry.size.width, height: 220 * offsetMultiplier)
      .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    .frame(height: 220)
    .onAppear {
      withAnimation { candlesVisible = true }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        withAnimation { starsVisible = true }
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        withAnimation { chalahVisible = true }
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
        sparkleAnimation = true
      }
    }
  }
}

