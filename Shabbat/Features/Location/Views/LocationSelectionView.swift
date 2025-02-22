import SwiftUI
import MapKit

struct LocationSelectionView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = LocationSelectionViewModel()
  @FocusState private var focused: Bool
  var onLocationSelected: (City) -> Void
  
  func onCitySelection(_ city: City) async {
    Task {
      // Get coordinates for the selected city
      if let completion = viewModel.searchCompletions.first(where: { $0.title == city.name }) {
        do {
          let coordinate = try await viewModel.getCoordinatesForCity(completion)
          let selectedCity = City(
            name: city.name,
            country: city.country,
            coordinate: coordinate
          )
          onLocationSelected(selectedCity)

          await MainActor.run {
            dismiss()
          }
        } catch {
          print("Error getting coordinates: \(error)")
        }
      }
    }
  }
  
  
  var body: some View {
    NavigationView {
      VStack {
        searchField
          .focused($focused)
        
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
      .navigationTitle("Select City")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .onAppear {
        focused = true
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
        Task {
          await onCitySelection(city)
        }
      } label: {
        VStack(alignment: .leading) {
          Text(city.name)
            .foregroundColor(.primary)
          Text(city.country)
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
