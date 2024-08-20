import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var selectedDistanceIndex = 0
    @State private var begDate = Date()
    @State private var endDate = Date()
    @State private var showingResults = false
    @State private var predictionResult: String = ""
    @State private var bestPerformanceDetails: String = "" // for displaying the healthkit data
    @State private var showBestPerformanceDetails: Bool = false // for toggling details display
    let raceDistances = ["5K", "10K", "Half Marathon", "Marathon"]
    let predictDistances: [Double] = [5.0, 10.0, 21.0975, 42.195] // Distances in kilometers
    @State private var showingShareSheet = false // Add a state variable to control the presentation of the share view
    @State private var shareTime = "null"
    @State private var showingFeedbackView = false // Add a state variable to control the presentation of the feedback view
    @State private var showingHealthKitInfoView = false // new state variable to control the presentation of the HealthKit info view
    
    
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

                        
                        Section {
                            Button("Get My Prediction") {
                                getMyPrediction()
                            }
                            .buttonStyle(ProminentButtonStyle())
                        }
                        
                        Section {
                            NavigationLink(destination: HealthKitInfoView()) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .imageScale(.medium)
                                    Text("HealthKit Data Usage")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    // Action to present the feedback form
                                    self.showingFeedbackView = true
                                }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                // Present the FeedbackView as a sheet
                                .sheet(isPresented: $showingFeedbackView) {
                                    FeedbackView()
                                }
                            }
                        }
                    )
                    
                } else {
                    // Results display
                    VStack(spacing: 20) {
                        Spacer()

                        Text(predictionResult)
                            .font(.title)
                        

                        if !bestPerformanceDetails.isEmpty {
                            Button(action: {
                                withAnimation {
                                    showBestPerformanceDetails.toggle()
                                }
                            }) {
                                Text("Show best workout performance from HealthKit used to calculate your prediction")
                                    .foregroundColor(.blue)
                            }
                            if showBestPerformanceDetails {
                                Text(bestPerformanceDetails)
                                    .transition(.scale)
                                    .fixedSize(horizontal: false, vertical: true) // Ensures text wraps and expands vertically.
                            }
                        }
                        
                        Spacer()
                        
                        Button("New Prediction") {
                            resetPrediction()
                        }
                        Link("Learn How This Works", destination: URL(string: "https://declankramper.notion.site/Race-Time-Predictor-App-6a485fdb13d84d07ab26e2aa7c3b2de0?pvs=4")!)
                        Button("Share Results") {
                            self.showingShareSheet = true
                        }.sheet(isPresented: $showingShareSheet) {
                            ActivityView(activityItems: [self.shareMessage()])
                        }
                    }.padding(50)
                }
            }
            .navigationBarTitle("Race Time Predictor")
            
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
            
            // Assuming begDate and endDate are correctly set by the user's input, get the result from findBestPerformance
            HealthKitManager.shared.getRunningWorkouts(begDate: self.begDate, endDate: self.endDate) { performances in
                let result = HealthKitManager.shared.findBestPerformance(workouts: performances, predictDistance: self.predictDistances[self.selectedDistanceIndex] * 1000)
                // Handle results display
                DispatchQueue.main.async {
                    if let bestPerformance = result.bestPerformance, let lowestPredictedTime = result.lowestPredictedTime {
                        self.predictionResult = "You are predicted to run a \(self.raceDistances[self.selectedDistanceIndex]) in \(self.formatTime(lowestPredictedTime))"
                        
                        self.bestPerformanceDetails = "Best Performance\nDate: \(bestPerformance.date.formatted(date: .abbreviated, time: .shortened))\nTime: \(formatTime(bestPerformance.time))\nDistance: \(formatDistance(bestPerformance.distance)) miles"
                    } else {
                        self.predictionResult = "No workouts found in the specified period."

                    }
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
        self.shareTime = "null"
        self.bestPerformanceDetails = ""
        self.showBestPerformanceDetails = false
    }
    
    // Function to format the time for result display
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Function to format the distance for result display
    func formatDistance(_ meters: Double) -> String {
        let miles = meters * 0.000621371 // Conversion factor from meters to miles
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: miles)) ?? "N/A"
    }

    
    // Function to construct the share message
    private func shareMessage() -> String {
        let distance = raceDistances[selectedDistanceIndex]
        // let shareTime = predictionResult.suffix(8)
        // Assume predictionResult is already formatted as "HH:MM:SS"
        return "Got my \(distance) race time prediction from #RaceTimePredictorApp: \(self.shareTime)! What's yours? #RaceDayGoals 🏃‍♀️🏅"
    }
    
    // structure for health kit message view
    struct HealthKitInfoView: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("HealthKit Integration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Our app uses HealthKit to access your workout data to provide accurate race time predictions. We value your privacy and only use this data to calculate predictions during your specified training period.")
                
                Text("Please ensure you've allowed access to your HealthKit workout data to get results.")
                
                Spacer()
            }
            .padding()
            .navigationTitle("About HealthKit")
        }
    }
    //structure for reusable button
    struct ProminentButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            HStack {
                       Spacer() // Add a Spacer to the left side
                       configuration.label
                           .padding()
                           .background(Color.blue) // Use your app’s theme color here
                           .foregroundColor(.white)
                           .clipShape(RoundedRectangle(cornerRadius: 8))
                           .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                           .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
                       Spacer() // Add a Spacer to the right side
                   }
            .background(Color.clear) // Ensure the HStack background is clear

        }
    }
}


// preview in canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
