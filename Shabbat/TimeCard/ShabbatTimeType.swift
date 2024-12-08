import SwiftUI

enum ShabbatTimeType {
  case candleLighting
  case havdalah
  
  var icon: String {
    switch self {
    case .candleLighting: return "sun.max.fill"
    case .havdalah: return "moon.fill"
    }
  }
  
  var iconColor: Color {
    switch self {
    case .candleLighting: return .orange
    case .havdalah: return .indigo
    }
  }
  
  var backgroundColor: Color {
    switch self {
    case .candleLighting: return .orange.opacity(0.1)
    case .havdalah: return .indigo.opacity(0.1)
    }
  }
  
  var timeColor: Color {
    switch self {
    case .candleLighting: return .orange
    case .havdalah: return .indigo
    }
  }
  
  var emoji: String {
    switch self {
    case .candleLighting: return "🕯️"
    case .havdalah: return "✨"
    }
  }
  
  var title: String {
    switch self {
    case .candleLighting: return String(localized: "Candle Lighting")
    case .havdalah: return String(localized: "Shabbat Ends")
    }
  }
}
