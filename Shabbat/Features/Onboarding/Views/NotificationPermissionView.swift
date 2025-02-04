import SwiftUI

struct NotificationPermissionView: View {
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.gray)
                .overlay(Text("Placeholder").foregroundColor(.white))
                .frame(maxHeight: .infinity)
            
            Rectangle()
                .fill(Color(.systemBackground))
                .overlay(
                  VStack(spacing: 8) {
                    Text("Shabbat Reminders")
                      .font(.title)
                      .fontWeight(.bold)
                      .fontWidth(Font.Width(0.15))
                    Text("Get the Shabbat Times on every friday morning.")
                      .font(.title3)
                      .multilineTextAlignment(.center)
                      .padding(.bottom, 24)
                    
                    Button("Enable Reminders") {
                      
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.bottom, 8)
                    
                    Button("Not Now")  {
                      
                    }
                    .foregroundStyle(.gray)

                  }.padding(.horizontal)
                )
                .frame(maxHeight: 400)
        }
        
    }
}

#Preview {
  
    NotificationPermissionView()
    .background(Color.gradientBackground(for: .light))
}
