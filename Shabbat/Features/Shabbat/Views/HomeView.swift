import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.layoutDirection) var layoutDirection
  @Environment(\.modelContext) private var modelContext
  
  @State private var viewModel: HomeViewModel
  @State private var showLocationPicker = false
  @State private var showParashaModal = false
  
  private var settingsManager: SettingsManager {
    SettingsManager(modelContext: modelContext)
  }
  
  init(modelContext: ModelContext) {
    _viewModel = State(initialValue: HomeViewModel(modelContext: modelContext))
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .center) {
          if viewModel.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let error = viewModel.error {
            ErrorMessage(error: error) {
              Task { await viewModel.loadShabbatTimes() }
            }
            .frame(maxWidth: .infinity)
            .padding()
          } else {
            ShabbatHeader(
              cityName: viewModel.cityName,
              showLocationPicker: { showLocationPicker = true }
            )
            
            ShabbatDateInfo(
              nextShabbatDates: viewModel.nextShabbatDates,
              daysUntilShabbat: viewModel.daysUntilShabbat,
              isShabbat: viewModel.isShabbat,
              shouldShowHolidayTitle: viewModel.shouldShowHolidayTitle,
              holidayTitle: viewModel.holidayTitle
            )
            .padding(.bottom, 24)

            
            ShabbatTimesView(viewModel: viewModel)
              .padding(.bottom, 8)
            
            if viewModel.shouldShowParashaButton {
              ParashaButton(
                parasahName: viewModel.parashaName,
                action: { showParashaModal = true }
              )
            }
          }
        }
        .padding()
      }
      .onAppear {
        Task {
          await viewModel.loadShabbatTimes()
          try await viewModel.loadParasha()
          
          // Schedule notifications in foreground when app is opened
          await BackgroundTaskService.shared.scheduleNotificationsInForeground(context: modelContext)
        }
      }
      .refreshable {
        do {
          try await viewModel.loadParasha()
          await viewModel.loadShabbatTimes()
          
          // Also reschedule notifications when user refreshes
          await BackgroundTaskService.shared.scheduleNotificationsInForeground(context: modelContext)
        } catch {
          // TODO: Handle errors
          print(error)
        }
      }
      .background(gradientBackground)
      .fullScreenCover(isPresented: $showLocationPicker) {
        LocationSelectionView { city in
          viewModel.saveNewCity(city: city)
          
          Task {
            await viewModel.loadShabbatTimes()
            
            // Schedule notifications for the new selected city
            await BackgroundTaskService.shared.scheduleNotificationsInForeground(context: modelContext)
          }
        }
      }
      .sheet(isPresented: $showParashaModal) {
        ParashaModalView(
          parasha: viewModel.parasha,
          isLoading: viewModel.isParashaLoading,
          dismiss: { showParashaModal = false }
        )
      }
      .overlay(alignment: .top) {
        GeometryReader { geom in
          VariableBlurView(maxBlurRadius: 10)
            .frame(height: geom.safeAreaInsets.top)
            .ignoresSafeArea()
        }
      }
    }
  }
  
  private var gradientBackground: some ShapeStyle {
    return LinearGradient(
      colors: colorScheme == .dark ? [
        .hsl(h: 48, s: 0, l: 2),    // Very dark gray
        .hsl(h: 48, s: 30, l: 10)   // Dark warm brown
      ] : [
        .hsl(h: 0, s: 0, l: 100),   // White
        .hsl(h: 48, s: 55, l: 84)   // Light warm beige
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}

#Preview("Jerusalem") {
  do {
    let container = try ModelContainer(for: City.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let jerusalemCity = City(
      name: "Jerusalem",
      country: "Israel",
      coordinate: CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
    )
    container.mainContext.insert(jerusalemCity)
    
    return HomeView(modelContext: container.mainContext)
      .modelContainer(container)
  } catch {
    return Text("Preview failed: \(error.localizedDescription)")
  }
}

#Preview("New York") {
  do {
    let container = try ModelContainer(for: City.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let nyCity = City(
      name: "New York",
      country: "USA",
      coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    )
    container.mainContext.insert(nyCity)
    return HomeView(modelContext: container.mainContext)
      .modelContainer(container)
  } catch {
    return Text("Preview failed: \(error.localizedDescription)")
  }
}
