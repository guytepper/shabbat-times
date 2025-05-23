import SwiftUI

struct CreditsView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        Button("Close") {
          dismiss()
        }
      }
      .padding()
      
      List {
        HStack {
          Spacer()
          Image("namaste")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 140)
            .scaledToFit()
          Spacer()
        }
        .listRowBackground(Color.clear)
        
        Section {
          Text("Made by [Guy Tepper](https://guytepper.com)")
          
          Text("Source code [available on GitHub](https://github.com/guytepper/shabbat-times)")
          
          Text("Shabbat times provided by [HebCal](https://hebcal.com)")
          
          Text("Parasha details provided by [Sefaria](https://www.sefaria.org.il)")
        }
      }
    }
  }
}

#Preview {
  CreditsView()
}
