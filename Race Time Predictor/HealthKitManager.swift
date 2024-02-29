import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private var healthStore: HKHealthStore?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let healthStore = healthStore else {
            completion(false, NSError(domain: "com.example.HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this device."]))
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success, error)
        }
    }

    func getRunningWorkouts(begDate: Date, endDate: Date, completion: @escaping ([Performance]) -> Void) {
        guard let healthStore = healthStore else {
            completion([])
            return
        }

        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: begDate, end: endDate, options: .strictStartDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [runningPredicate, datePredicate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else {
                completion([])
                return
            }

            let performances = workouts.map {
                Performance(id: $0.uuid, time: $0.duration, distance: $0.totalDistance?.doubleValue(for: .meter()) ?? 0, date: $0.startDate)
            }
            completion(performances)
        }

        healthStore.execute(query)
    }

    func findBestPerformance(workouts: [Performance], predictDistance: Double) -> (bestPerformance: Performance?, lowestPredictedTime: Double?) {
        guard !workouts.isEmpty else { return (nil, nil) }

        var bestPerformance: Performance?
        var lowestPredictedTime: Double?

        for workout in workouts {
            let predictedTime = calculatePredictedTime(for: workout, predictDistance: predictDistance)
            if lowestPredictedTime == nil || predictedTime < lowestPredictedTime! {
                lowestPredictedTime = predictedTime
                bestPerformance = workout
            }
        }
        
        return (bestPerformance, lowestPredictedTime)
    }


    func calculatePredictedTime(for performance: Performance, predictDistance: Double) -> Double {
        // Pete Riegel’s formula: T2 = T1 * (D2 / D1) ^ 1.06
        let T1 = performance.time
        let D1 = performance.distance
        let D2 = predictDistance

        return T1 * pow((D2 / D1), 1.06)
    }
}

struct Performance {
    var id: UUID
    var time: Double // Assuming time is in seconds
    var distance: Double // Assuming distance is in meters
    var date: Date // Adding date to store the workout's start date

}
