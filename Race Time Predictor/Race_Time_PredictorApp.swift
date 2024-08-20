//
//  Race_Time_PredictorApp.swift
//  Race Time Predictor
//
//  Created by Declan Kramper on 2/21/24.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore

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
