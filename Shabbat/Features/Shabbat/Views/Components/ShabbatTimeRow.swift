import SwiftUI

struct ShabbatTimeRow: View {
  let title: String
  let time: Date
  let timeZone: TimeZone
  let timeColor: Color
  
  private var formattedTime: String {
    let formatter = DateFormatter()
    
    // Check if current locale is Hebrew
    let currentLocale = Locale.current
    let isHebrew = currentLocale.language.languageCode!.identifier == "he"
    
    if isHebrew {
      // For Hebrew, use 24-hour format with POSIX locale to avoid Hebrew AM/PM
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "HH:mm"
    } else {
      // For other locales (like English), use 12-hour format with AM/PM
      formatter.locale = currentLocale
      formatter.dateFormat = "h:mm a"
    }
    
    formatter.timeZone = timeZone
    return formatter.string(from: time)
  }
  
  private var accessibleTimeDescription: String {
    let formatter = DateFormatter()
    formatter.timeZone = timeZone
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: time)
  }
    
  var body: some View {
    HStack(alignment: .center) {
      Text(title)
        .font(.headline)
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 2) {
        Text(formattedTime)
          .foregroundColor(timeColor)
          .font(.title2)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
      }
    }
    .padding(.vertical, 16)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title)")
    .accessibilityValue(formattedTime)
    .accessibilityAddTraits(.isStaticText)
  }
}
