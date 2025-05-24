import SwiftUI
import SwiftData
import UserNotifications

struct RemindersView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext
  
  @Binding var tabSelection: Int
  @State private var showNotification: Bool = false
  
  private var settingsManager: SettingsManager {
    SettingsManager(modelContext: modelContext)
  }
  
  private var isHebrew: Bool {
    Locale.current.language.languageCode?.identifier == "he"
  }
  
  private var topPadding: CGFloat {
    isHebrew ? 135 : 120
  }
  
  private var fridayDateText: String {
    let calendar = Calendar.current
    let today = Date()
    let todayWeekday = calendar.component(.weekday, from: today)
    
    // If today is Friday, use today's date, otherwise calculate the next Friday
    let targetDate: Date
    if todayWeekday == 6 {
      targetDate = today
    } else {
      // Calculate next Friday
      let daysUntilFriday: Int = (6 - todayWeekday + 7) % 7
      let adjustedDays = daysUntilFriday == 0 ? 7 : daysUntilFriday
      targetDate = calendar.date(byAdding: .day, value: adjustedDays, to: today) ?? today
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    
    // Add ordinal suffix
    let day = calendar.component(.day, from: targetDate)
    let ordinalFormatter = NumberFormatter()
    ordinalFormatter.numberStyle = .ordinal
    let ordinalDay = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
    
    let baseString = formatter.string(from: targetDate)
    let dayString = formatter.dateFormat.contains("d") ? String(day) : ""
    return baseString.replacingOccurrences(of: dayString, with: ordinalDay)
  }
  
  var body: some View {
    VStack {
      ZStack {
        Image("iphone_mock")
          .resizable()
          .scaledToFit()
          .frame(maxWidth: 320)
          .padding(24)
          .mask(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.2),
                .init(color: .clear, location: 0.85),
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
        
        // Notification Banner - Centered
        if showNotification {
          NotificationBanner()
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
        
        VStack {
          Text(fridayDateText)
            .foregroundStyle(.white)
            .font(.headline)
            .fontWeight(.bold)
            .opacity(0.8)
          
          Text("09:00")
            .foregroundStyle(.white)
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .font(.system(size: 52))
          
          Spacer()
        }
        .padding(.top, topPadding)
        .opacity(0.8)
        
      }
      .onAppear {
        // Show notification with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showNotification = true
          }
        }
      }
      
      Spacer()
      
      VStack(spacing: 8) {
        Text("Shabbat Notification")
          .font(.title)
          .fontWeight(.bold)
          .fontWidth(Font.Width(0.05))
        
        Text("Receive candle lightning times every friday morning.")
          .font(.body)
          .multilineTextAlignment(.center)
          .padding(.bottom, 12)
        
        Button("Enable Notifications") {
          Task {
            do {
              let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
              
              if granted {
                settingsManager.updateSettings { settings in
                  settings.finishedOnboarding = true
                  settings.morningNotification = true
                }
                
                // Schedule a background notification refresh
                BackgroundTaskService.shared.scheduleAppRefresh(Date())
              } else {
                print("Notification permission denied.")
              }
            } catch {
              print("Error requesting notification authorization: \(error.localizedDescription)")
            }
          }
        }
        .frame(maxWidth: 400)
        .padding(16)
        .background(.blue)
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.bottom, 8)
        
        Button("Not Now")  {
          settingsManager.updateSettings { settings in
            settings.finishedOnboarding = true
          }
        }
        .foregroundStyle(Color(uiColor: .label))
      }
      .padding()
    }
  }
}

struct NotificationBanner: View {
  var body: some View {
    HStack(spacing: 12) {
      HStack {
        Image("shabbat_icon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 40, height: 40)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(.white)
          .shadow(color: .black.opacity(0.1), radius: 1)
      )
      
      VStack(alignment: .leading, spacing: 2) {
        Text("Shabbat Times")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
        
        Text("Candle lighting today at 6:23 PM. Shabbat Shalom!")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.leading)
      }
      
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(.regularMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    )
  }
}

#Preview {
  TabView {
    RemindersView(tabSelection: .constant(1))
      .background(Color.gradientBackground(for: .light))
  }.tabViewStyle(.page)
    .ignoresSafeArea()
}
