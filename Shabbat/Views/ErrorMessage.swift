import SwiftUI

struct ErrorMessage: View {
  var error: Error
  var onRetry: () async -> Void
  
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title)
        .foregroundColor(.orange)
      Text("Error loading times")
        .font(.headline)
      Text(error.localizedDescription)
        .font(.subheadline)
        .foregroundColor(.secondary)
      Button("Retry") {
        Task {
          await onRetry()
        }
      }
      .buttonStyle(.bordered)
    }
  }
}

