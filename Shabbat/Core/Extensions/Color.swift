import SwiftUI

extension Color {
  static func hsl(h: Double, s: Double, l: Double, a: Double = 1) -> Color {
    Color(hue: h/360, saturation: s/100, brightness: l/100, opacity: a)
  }
  
  static func gradientBackground(for colorScheme: ColorScheme) -> LinearGradient {
    let colors: [Color] = colorScheme == .dark ? [
      .hsl(h: 48, s: 0, l: 2),    // Very dark gray
      .hsl(h: 48, s: 30, l: 10)   // Dark warm brown
    ] : [
      .hsl(h: 0, s: 0, l: 100),   // White
      .hsl(h: 48, s: 55, l: 84)   // Light warm beige
    ]
    
    return LinearGradient(
      colors: colors,
      startPoint: .top,
      endPoint: .bottom
    )
  }
}
