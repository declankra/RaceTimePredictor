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

    // Request HealthKit permission
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [HKQuantityType.workoutType()]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                }
                print("HealthKit authorization success: \(success)")
                completion(success)
            }
        }
    }
    
    // Get health data from HealthKit
    func getHealthData() {
        guard let begDate = begDate, let endDate = endDate else {
            print("Begin or end date is nil")
            return
        }
        let sampleType = HKSampleType.workoutType()
        
        // Define the predicate to filter workouts by date and by running activity type
        let datePredicate = HKQuery.predicateForSamples(withStart: begDate, end: endDate, options: .strictStartDate)
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, runningPredicate])
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: combinedPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] (_, samples, error) in
            guard let self = self else {
                print("Self is nil")
                return
            }
            
            if let error = error {
                print("An error occurred fetching the user's workouts: \(error.localizedDescription)")
                return
            }
            
            guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                print("No workouts found or not a workout sample")
                return
            }
            
            print("Fetched \(workouts.count) workouts of type 'Running'")
            self.findClosestPerf(workouts: workouts)
        }
        
        healthStore.execute(query)
    }

    
    // Find the closest performance
    private func findClosestPerf(workouts: [HKWorkout]) {
            DispatchQueue.global(qos: .userInitiated).async {
                var bestPerformance: Performance?
                workouts.forEach { workout in
                    let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                    if distance > self.longestDist && distance < self.predictDistance {
                        self.longestDist = distance
                        bestPerformance = Performance(time: workout.duration, distance: distance)
                    }
                }
                
                DispatchQueue.main.async {
                    if let bestPerf = bestPerformance {
                        print("Found closest performance: \(bestPerf)")
                        self.closestPerf = bestPerf
                        self.predictedTime = self.calculateTime(distance: self.predictDistance, closestPerf: bestPerf)
                        print("Predicted time: \(self.predictedTime ?? -1)")
                    } else {
                        print("No closest performance found")
                    }
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
