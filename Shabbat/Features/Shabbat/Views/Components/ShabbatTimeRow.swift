import SwiftUI

struct ShabbatTimeRow: View {
  let title: String
  let time: String
  let timeZone: String
  let timeColor: Color
  
  var body: some View {
    HStack(alignment: .center) {
      Text(title)
        .font(.headline)
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 2) {
        Text(time)
          .foregroundColor(timeColor)
          .font(.title2)
          .fontWeight(.semibold)
          .fontDesign(.rounded)
      }
    }
    .padding(.vertical, 16)
  }
}
