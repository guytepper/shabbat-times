import SwiftUI
import MapKit

struct City: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: City, rhs: City) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
final class LocationSelectionViewModel: NSObject {
    private var searchCompleter: MKLocalSearchCompleter
    var searchText = ""
    var cities: [City] = []
    var isSearching = false
    var error: Error?
    
    override init() {
        searchCompleter = MKLocalSearchCompleter()
        super.init()
        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        
        guard !text.isEmpty else {
            cities = []
            return
        }
        
        searchCompleter.queryFragment = text
    }
  
  func setup() {
      // Need to set delegate after self is initialized
      searchCompleter.delegate = self
  }
  
}

extension LocationSelectionViewModel: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task { @MainActor in
      cities = completer.results.map { result in
        City(
          name: result.title,
          title: result.title,
          subtitle: result.subtitle,
          coordinate: CLLocationCoordinate2D() // Placeholder until we perform the search
        )
      }
    }
  }
  
  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    Task { @MainActor in
      self.error = error
      cities = []
    }
  }
}

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
    .onAppear {
      viewModel.setup()
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
    print("Selected city: \(city.name)")
  }
}
