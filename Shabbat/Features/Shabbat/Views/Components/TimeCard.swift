import SwiftUI

struct TimeCard: View {
  let timeType: ShabbatTimeType
  let date: Date
  
  init(timeType: ShabbatTimeType, date: Date) {
    self.timeType = timeType
    self.date = date
  }
  
  private var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
  }()
  
  private var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
    return formatter
  }()
  
  var body: some View {
    HStack {
      Image(systemName: timeType.emoji)
        .font(.title)
      
      VStack(alignment: .leading) {
        VStack(alignment: .leading, spacing: 4.0) {
          Text(timeType.title)
            .font(.body)
          
          Text(timeFormatter.string(from: date))
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(timeType.timeColor)
          
          Text(dateFormatter.string(from: date))
            .font(.subheadline)
        }
      }
      
      Spacer()
      
      Text(timeType.emoji)
          .font(.title)
    }
    .padding()
    .background(timeType.backgroundColor)
    .cornerRadius(12)
  }
}
