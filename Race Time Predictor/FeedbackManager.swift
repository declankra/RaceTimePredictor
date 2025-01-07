import SwiftUI
import FirebaseAnalytics

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @AppStorage("predictionCount") private var predictionCount = 0
    @AppStorage("hasShownInAppFeedback") private var hasShownInAppFeedback = false
    @Published var showFeedbackAlert = false
    
    private init() {}
    
    func incrementPredictionCount() {
        predictionCount += 1
        checkAndShowFeedback()
    }
    
    private func checkAndShowFeedback() {
        if !hasShownInAppFeedback && predictionCount > 0 && predictionCount % 3 == 0 {
            showFeedbackAlert = true
            Analytics.logEvent("feedback_alert_shown", parameters: [
                "prediction_count": predictionCount
            ])
        }
    }
    
    // Added new function to set feedback status
    func setFeedbackProvided() {
        hasShownInAppFeedback = true
        showFeedbackAlert = false
    }
}
