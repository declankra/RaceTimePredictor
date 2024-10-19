//
//  Race_Time_PredictorApp.swift
//  Race Time Predictor
//
//  Created by Declan Kramper on 2/21/24.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      // Set debug logging to false for release builds
      Firestore.firestore().settings = FirestoreSettings()
      Firestore.enableLogging(false)
    
      // Enable analytics debug mode in development
      #if DEBUG
      Analytics.setAnalyticsCollectionEnabled(true)
      #endif
      
      return true
  }
}

@main
struct RaceTimePredictorApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
