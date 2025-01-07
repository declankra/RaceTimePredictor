import StoreKit
import SwiftUI

class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    @AppStorage("appLaunchCount") private var appLaunchCount = 0
    
    private init() {}
    
    func incrementAppLaunch() {
        appLaunchCount += 1
        requestReviewIfNeeded()
    }
    
    private func requestReviewIfNeeded() {
        // Request review on second app launch if not requested before
        guard !hasRequestedReview && appLaunchCount >= 2 else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                self.hasRequestedReview = true
            }
        }
    }
}
