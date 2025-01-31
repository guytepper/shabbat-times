import SwiftUI

struct ErrorMessage: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Oy! Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: retry)
                .buttonStyle(.bordered)
        }
    }
} 
