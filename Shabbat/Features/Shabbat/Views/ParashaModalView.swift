import SwiftUI

struct ParashaModalView: View {
  let parasha: ParashaInfo?
  let isLoading: Bool
  let dismiss: () -> Void
  @State private var showErrorAlert = false
  
  var isHebrewLocale: Bool {
    Locale.current.language.languageCode?.identifier == "he"
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let parasha = self.parasha {
          VStack(alignment: .leading) {
            Text(parasha.name)
              .font(isHebrewLocale ? .largeTitle : .title)
              .fontDesign(isHebrewLocale ? .rounded : .serif)
              .fontWeight(.bold)
              .padding(.bottom, 8)
            
            Text(parasha.description)
              .lineSpacing(5)
              .padding(.bottom)
              .contextMenu {
                Button {
                  UIPasteboard.general.string = parasha.description
                } label: {
                  Label("Copy", systemImage: "doc.on.doc")
                }
              }
            
            if !parasha.url.isEmpty {
              externalLinkButton
            }
          }
          .padding(.horizontal)
        }
      }
      .background(.thinMaterial)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Close", action: dismiss)
        }
      }
    }
  }
  
  var externalLinkButton: some View {
    Button {
      let baseURL = "https://www.sefaria.org.il/"
      let langPref = isHebrewLocale ? "?lang=he" : "?lang=en"
      
      if let url = URL(string: baseURL + parasha!.url + langPref) {
        UIApplication.shared.open(url)
      } else {
        showErrorAlert = true
      }
    } label: {
      HStack {
        Image(systemName: "book")
        Text("Read on Sefaria")
        Spacer()
      }
      .padding()
      .background(.brown.gradient.tertiary)
      .foregroundColor(.white)
      .cornerRadius(8)
    }
    .alert("Unable to Open Link", isPresented: $showErrorAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Oy! The link to Sefaria could not be opened.")
    }
  }
}

#Preview {
  ParashaModalView(
    parasha: ParashaInfo(
      name: "Genesis",
      hebrewName: "בְּרֵאשִׁית",
      url: "https://www.sefaria.org/Genesis.1.1-6.8",
      description: "The first parasha in the Torah, covering Genesis 1:1-6:8. It tells the story of Creation, Adam and Eve in the Garden of Eden, Cain and Abel, and the generations leading to Noah.",
      hebrewDescription: "הפרשה הראשונה בתורה, מכסה את בראשית א:א-ו:ח. מספרת את סיפור הבריאה, אדם וחוה בגן עדן, קין והבל, והדורות המובילים לנח."
    ),
    isLoading: false,
    dismiss: {}
  )
}
