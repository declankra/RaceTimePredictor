import SwiftUI


struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var selectedDistanceIndex = 0
    let raceDistances = ["5K", "10K", "Half Marathon", "Marathon"]
    
    @State private var begDate = Date()
    @State private var endDate = Date()
    //@State private var prediction: (time: TimeInterval, distance: Double)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter Your Race Distance")) {
                    Picker("Select distance:", selection: $selectedDistanceIndex) {
                        ForEach(0 ..< raceDistances.count, id: \.self) {
                            Text(self.raceDistances[$0])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Select Training Period for Prediction")) {
                    DatePicker("Beginning Date", selection: $begDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Get My Prediction") {
                        healthKitManager.predictDistance = distanceForSelectedIndex(selectedDistanceIndex)
                        healthKitManager.begDate = begDate
                        healthKitManager.endDate = endDate
                        healthKitManager.getHealthData()
                    }
                }
                
                // Results display section
                if healthKitManager.closestPerf != nil {
                    Section(header: Text("Prediction")) {
                        // Access predictedTime through healthKitManager
                        Text("You are predicted to run a \(raceDistances[selectedDistanceIndex]) in \(formatTime(healthKitManager.predictedTime ?? 0))")
                    }
                }
            }
            .navigationBarTitle("Race Time Predictor")
        }
        .onAppear {
            healthKitManager.requestAuthorization()
        }
    }
    
    private func distanceForSelectedIndex(_ index: Int) -> Double {
            // Convert the selected distance to meters
            switch raceDistances[index] {
                case "5K":
                    return 5000 // meters
                case "10K":
                    return 10000 // meters
                case "Half Marathon":
                    return 21097.5 // meters
                case "Marathon":
                    return 42195 // meters
                default:
                    return 0 // meters
            }
        }
        
    private func formatTime(_ time: TimeInterval) -> String {
            // Format the time for display
            let hours = Int(time) / 3600
            let minutes = Int(time) % 3600 / 60
            let seconds = Int(time) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
