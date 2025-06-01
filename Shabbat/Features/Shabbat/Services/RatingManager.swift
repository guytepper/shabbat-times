import Foundation
import StoreKit
import UIKit

/// Manages App Store rating - asks once after 4th usage
class RatingManager {
  static let shared = RatingManager()
  
  private let userDefaults = UserDefaults.standard
  private let targetUsageCount = 4 
  
  private enum Keys {
    static let usageCount = "app_usage_count"
    
    /// The user might have rated the app manually via the settings screen
    static let hasRatedApp = "has_rated_app"
  }
  
  private init() {}
  
  /// Increments the app usage counter and checks if we should prompt for rating
  func incrementUsageCount() {
    let currentCount = userDefaults.integer(forKey: Keys.usageCount)
    let newCount = currentCount + 1
    userDefaults.set(newCount, forKey: Keys.usageCount)
    
    if newCount == targetUsageCount && !userDefaults.bool(forKey: Keys.hasRatedApp) {
      requestReview()
    }
  }
  
  /// Marks that the user has rated the app (call when user uses manual rate button)
  func markAsRated() {
    userDefaults.set(true, forKey: Keys.hasRatedApp)
  }
  
  /// Requests a review using Apple's native prompt
  private func requestReview() {
    // Mark as rated so we don't ask again
    markAsRated()
    
    DispatchQueue.main.async {
      if let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
      }
    }
  }
  
  // MARK: - Debug Methods
  
  #if DEBUG
  func resetRatingData() {
    userDefaults.removeObject(forKey: Keys.usageCount)
    userDefaults.removeObject(forKey: Keys.hasRatedApp)
  }
  
  func getCurrentState() -> [String: Any] {
    return [
      "usageCount": userDefaults.integer(forKey: Keys.usageCount),
      "hasRatedApp": userDefaults.bool(forKey: Keys.hasRatedApp),
      "willPromptOnNextUsage": userDefaults.integer(forKey: Keys.usageCount) == 3 && !userDefaults.bool(forKey: Keys.hasRatedApp)
    ]
  }
  #endif
}
