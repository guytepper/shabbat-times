import SwiftUI

struct ShabbatTimeRow: View {
  let title: String
  let time: Date
  let timeZone: TimeZone
  let timeColor: Color
  
  private var formattedTime: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.timeZone = timeZone
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
  }
}
