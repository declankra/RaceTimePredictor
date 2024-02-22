//
//  HealthKitManager.swift
//  Race Time Predictor
//
//  Created by Declan Kramper on 2/22/24.
//

import HealthKit
import SwiftUI

struct Performance: Identifiable {
    let id = UUID()
    var time: TimeInterval
    var distance: Double
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var predictDistance: Double = 0 // user selected distance
    @Published var begDate: Date? // start date of health data retrieval
    @Published var endDate: Date? // last date of health data retrieval
    @Published var closestPerf: Performance? // performance used for calculation
    @Published var longestDist: Double = 0 // stores longest distance
    @Published var predictedTime: TimeInterval? // holds the predicted time result


    func requestAuthorization() {
        // Define the health data types that we want to write and read
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [HKQuantityType.workoutType()]
        
        // Request authorization for those types
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                // Handle the error here.
            }
        }
    }
    
    // Get health data from HealthKit
    func getHealthData() {
        // Define the sample type to read
        let sampleType = HKSampleType.workoutType()

        // Use a predicate to read samples from the HealthKit store
        let predicate = HKQuery.predicateForSamples(withStart: begDate, end: endDate, options: .strictStartDate)

        // Create the query
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            guard error == nil else {
                print("An error occurred fetching the user's workouts: \(error!.localizedDescription)")
                return
            }

            if let workouts = samples as? [HKWorkout] {
                self.findClosestPerf(workouts: workouts)
            }
            
            DispatchQueue.main.async {
                    if let closest = self.closestPerf {
                        let predictedTime = self.calculateTime(distance: self.predictDistance, closestPerf: closest)
                        // This should be a @Published property or a callback to update ContentView
                        self.predictedTime = predictedTime
                    }
                }
        }
        // Execute the query
        healthStore.execute(query)
    }
    
    // Find the closest performance
    func findClosestPerf(workouts: [HKWorkout]) {
          var bestPerformance: Performance?

          for workout in workouts where workout.workoutActivityType == .running || workout.workoutActivityType == .walking {
              let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0

              if distance > longestDist && distance < predictDistance {
                  longestDist = distance
                  bestPerformance = Performance(time: workout.duration, distance: distance)
              }
          }
          
          if let bestPerf = bestPerformance {
              DispatchQueue.main.async {
                  self.closestPerf = bestPerf
                  self.predictedTime = self.calculateTime(distance: self.predictDistance, closestPerf: bestPerf)
              }
          }
      }
      
    
    // Calculate predicted time using Pete Riegel’s formula
        func calculateTime(distance predictDistance: Double, closestPerf: Performance) -> TimeInterval {
            let T1 = closestPerf.time
            let D1 = closestPerf.distance
            let D2 = predictDistance
            
            // Pete Riegel’s formula: T2 = T1 * (D2/D1) ^ 1.06
            let T2 = T1 * pow((D2/D1), 1.06)
            return T2
        }
    }
