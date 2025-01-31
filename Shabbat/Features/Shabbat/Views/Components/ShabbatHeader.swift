import SwiftUI

struct ShabbatHeader: View {
    let cityName: String
    let showLocationPicker: () -> Void
    @Environment(\.layoutDirection) var layoutDirection
    
    var body: some View {
        VStack {
            Button(action: showLocationPicker) {
                Text(cityName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            Text("🥖")
                .font(.system(size: 120))
                .rotationEffect(.degrees(layoutDirection == .rightToLeft ? 45 : -45))
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
    }
} 