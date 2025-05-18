import SwiftUI

struct ShabbatHeader: View {
  let cityName: String
  let showLocationPicker: () -> Void
  
  @State private var isAnimating = false
  @State private var currentIconIndex = 0
  @State private var isCustomIcon = false
  
  private let availableIcons = ["david_star", "candles", "chalah", "synagouge", "stars"]
  
  private var defaultDayIcon: String {
    let calendar = Calendar.current
    let today = calendar.component(.weekday, from: Date())
    let now = Date()
    
    // Friday icons
    if today == 6 {
      // TODO: Replace this with actual candle lighting time
      let candleLightingTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now
      
      if now < candleLightingTime {
        return "chalah"
      } else if now > calendar.date(byAdding: .hour, value: 3, to: candleLightingTime) ?? now {
        return "synagouge"
      } else {
        return "candles"
      }
    }
    
    // Saturday icons
    if today == 7 {
      if let morningCutoff = calendar.date(bySettingHour: 11, minute: 30, second: 0, of: now),
         let eveningCutoff = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now) {
        if now < morningCutoff {
          return "synagouge"
        }
        else if now > eveningCutoff {
          return "stars"
        } else {
          return "david_star"
        }
      }
    }
    
    return "david_star"
  }
  
  private var dayIcon: String {
    isCustomIcon ? availableIcons[currentIconIndex] : defaultDayIcon
  }
  
  var body: some View {
    VStack {
      Button(action: showLocationPicker) {
        Text(cityName)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundStyle(.blue)
      }
      
      Image(dayIcon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 180)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        .onTapGesture {
          withAnimation {
            isAnimating = true
            isCustomIcon = true
            currentIconIndex = (currentIconIndex + 1) % availableIcons.count
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
          }
        }
    }
  }
}
