import Foundation

struct AppEnvironment {
  static var isDebug: Bool {
    #if DEBUG
      return true
    #else
      return false
    #endif
  }

  static var isTestFlight: Bool {
    guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
      return false
    }
    return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
  }
  
  static var shouldShowDebugView: Bool {
    return isDebug || isTestFlight
  }
} 