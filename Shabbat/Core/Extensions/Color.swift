import SwiftUI

extension Color {
    static func hsl(h: Double, s: Double, l: Double, a: Double = 1) -> Color {
        Color(hue: h/360, saturation: s/100, brightness: l/100, opacity: a)
    }
}
