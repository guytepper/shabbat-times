import SwiftUI

struct LocationSelectionView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = LocationSelectionViewModel()
  var onLocationSelected: (City) -> Void
  
  var body: some View {
    NavigationView {
      VStack {
        searchField
        
        if viewModel.isSearching {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.error {
          ErrorMessage(error: error) {
            // No retry needed for local search
          }
        } else {
          citiesList
        }
      }
      .navigationTitle("Select Location")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
  
  private var searchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
      
      TextField("Search for a city...", text: $viewModel.searchText)
        .textFieldStyle(.plain)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.words)
        .onChange(of: viewModel.searchText) { _, newValue in
          viewModel.updateSearchText(newValue)
        }
      
      if !viewModel.searchText.isEmpty {
        Button {
          viewModel.searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(8)
    .background(Color(.systemGray6))
    .cornerRadius(8)
    .padding()
  }
  
  private var citiesList: some View {
    List(viewModel.cities) { city in
      Button {
        onLocationSelected(city)
        dismiss()
      } label: {
        VStack(alignment: .leading) {
          Text(city.title)
            .foregroundColor(.primary)
          Text(city.subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .listStyle(.plain)
  }
}

#Preview {
  LocationSelectionView { city in
    print("Selected city: \(city.coordinate)")
  }
}
