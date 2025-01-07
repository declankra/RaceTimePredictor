import StoreKit
import SwiftUI

class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    @AppStorage("predictionsCount") private var predictionsCount = 0
    
    private init() {}
    
    func incrementPredictionsCount() {
        predictionsCount += 1
        requestReviewIfNeeded()
    }
    
    private func requestReviewIfNeeded() {
        guard !hasRequestedReview && predictionsCount >= 3 else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                self.hasRequestedReview = true
            }
        }
    }
}

