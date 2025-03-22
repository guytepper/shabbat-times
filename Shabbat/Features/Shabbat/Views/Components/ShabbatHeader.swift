import SwiftUI

struct ShabbatHeader: View {
  let cityName: String
  let showLocationPicker: () -> Void
  
  private var dayIcon: String {
    let calendar = Calendar.current
    let today = calendar.component(.weekday, from: Date())
    let now = Date()
    
    // Friday icons
    if today == 6 {
      // TODO: Replace this with actual candle lighting time
      let candleLightingTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now
      
      if now < candleLightingTime {
        return "🍞"
      } else if now > calendar.date(byAdding: .hour, value: 3, to: candleLightingTime) ?? now {
        return "🍷"
      } else {
        return "🕯"
      }
    }
    
    // Saturday icons
    if today == 7 {
      if let morningCutoff = calendar.date(bySettingHour: 11, minute: 30, second: 0, of: now),
         let eveningCutoff = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now) {
        if now < morningCutoff {
          return "🕍"
        }
        else if now > eveningCutoff {
          return "✨"
        } else {
          return "✡️"
        }
      }
    }
    
    return "✡️"
  }
  
  var body: some View {
    VStack {
      Button(action: showLocationPicker) {
        Text(cityName)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundStyle(.blue)
      }
      
      Text(dayIcon)
        .font(.system(size: 120))
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
  }
}
