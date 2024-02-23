import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var selectedDistanceIndex = 0
    @State private var begDate = Date()
    @State private var endDate = Date()
    @State private var showingResults = false
    @State private var predictionResult: String = ""
    let raceDistances = ["5K", "10K", "Half Marathon", "Marathon"]
    let predictDistances: [Double] = [5.0, 10.0, 21.0975, 42.195] // Distances in kilometers
    
    var body: some View {
        NavigationView {
            VStack {
                if !showingResults {
                    Form {
                        Section(header: Text("Select your race distance")) {
                            Picker("Race Distance", selection: $selectedDistanceIndex) {
                                ForEach(0..<raceDistances.count, id: \.self) {
                                    Text(self.raceDistances[$0])
                                }
                            }
                        }
                        Section(header: Text("Select training period for prediction")) {
                            DatePicker("Beginning Date", selection: $begDate, in: ...Date(), displayedComponents: .date)
                            DatePicker("End Date", selection: $endDate, in: ...Date(), displayedComponents: .date)
                        }
                        
                        Button("Get My Prediction") {
                            getMyPrediction()
                        }.buttonStyle(.automatic)
                    }
                } else {
                    // Results display
                    VStack(spacing: 20) {
                        
                        Text(predictionResult)
                            .font(.title)
                        Button("New Prediction") {
                            resetPrediction()
                        }
                        Link("Learn How This Works", destination: URL(string: "https://declankramper.notion.site/Race-Time-Predictor-App-6a485fdb13d84d07ab26e2aa7c3b2de0?pvs=4")!)
                        Button("Share Results") {
                            shareResults()
                    }
                    }
                }
            }
            .navigationBarTitle("Race Time Predictor")
            .navigationBarItems(trailing: Button(action: {
                showingResults = false
            }) {
                if showingResults {
                    Text("Edit")
                }
            })
        }
    }
    
    private func getMyPrediction() {
        HealthKitManager.shared.requestAuthorization { success, error in
            guard success else {
                // Handle the error if authorization was not successful
                DispatchQueue.main.async {
                    self.predictionResult = "Error: \(error?.localizedDescription ?? "Could not access HealthKit data.")"
                    self.showingResults = true // Show results area to display the error message
                }
                return
            }
            
            // Assuming begDate and endDate are correctly set by the user's input
            HealthKitManager.shared.getRunningWorkouts(begDate: self.begDate, endDate: self.endDate) { performances in
                        let result = HealthKitManager.shared.findBestPerformance(workouts: performances, predictDistance: self.predictDistances[self.selectedDistanceIndex] * 1000)
                        
                        guard let bestPerformance = result.bestPerformance, let lowestPredictedTime = result.lowestPredictedTime else {
                            DispatchQueue.main.async {
                                self.predictionResult = "No workouts found in the specified period."
                                self.showingResults = true
                            }
                            return
                        }
            
                // Display the best performance for reference
                    // let bestTime = bestPerformance.time
                    // let bestDistance = bestPerformance.distance
                    // let bestDate = bestPerformance.date // need to add date to bestPerformance by first adding to Performance structure
                
                DispatchQueue.main.async {
                               self.predictionResult = "You are predicted to run a \(self.raceDistances[self.selectedDistanceIndex]) in \(self.formatTime(lowestPredictedTime))"
                               self.showingResults = true
                           }
                }
            }
        
    }

    
    private func resetPrediction() {
        self.showingResults = false
        self.selectedDistanceIndex = 0
        self.begDate = Date()
        self.endDate = Date()
        self.predictionResult = ""
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
           let hours = Int(time) / 3600
           let minutes = (Int(time) % 3600) / 60
           let seconds = Int(time) % 60
           return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
       }
    
    private func shareResults() {
        // The actual sharing functionality requires UIKit integration
        // Use UIActivityViewController in UIKit to share the results
        // This part of the code cannot be directly implemented in SwiftUI without using UIViewControllerRepresentable
        print("Share functionality to be implemented with UIActivityViewController")
    }
}

// preview in canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
