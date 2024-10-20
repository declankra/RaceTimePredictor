import SwiftUI
import HealthKit
import FirebaseAnalytics

struct ContentView: View {
    @State private var selectedDistanceIndex = 0
    @State private var begDate = Date()
    @State private var endDate = Date()
    @State private var showingResults = false
    @State private var predictedTime: TimeInterval? = nil
    @State private var requiredPace: Double? = nil
    @State private var bestPerformanceDetails: String = ""
    @State private var showBestPerformanceDetails: Bool = false
    let raceDistances = ["5K", "10K", "Half Marathon", "Marathon"]
    let predictDistances: [Double] = [5.0, 10.0, 21.0975, 42.195]
    @State private var showingShareSheet = false
    @State private var shareTime = "null"
    @State private var showingFeedbackView = false
    @State private var showingHealthKitInfoView = false
    @State private var errorMessage: String? = nil
    @State private var selectedPaceUnit = 0 // 0 for min/mile, 1 for min/km
    let paceUnits = ["min/mile", "min/km"]


    var body: some View {
            NavigationView {
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 70) {
                            if !showingResults {
                                raceDistanceSection
                                trainingPeriodSection
                                paceUnitSection
                                getPredictionButton
                                healthKitInfoLink
                            } else {
                                resultsSection
                            }
                        }
                        .padding()
                        .padding(.bottom, 90) // Adjust padding as needed
                    }

                    feedbackButton
                        .padding()
                }
                .navigationBarTitle("Race Time Predictor")
            }
    #if DEBUG
    .onAppear {
        Analytics.setAnalyticsCollectionEnabled(true)
    }
    #endif
        }
       
    var raceDistanceSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Select your race distance")
                .font(.title3)
                .fontWeight(.bold)
            HStack{
                Text("Race Distance")
                    .font(.body)
                Picker("Race Distance", selection: $selectedDistanceIndex) {
                    ForEach(0..<raceDistances.count, id: \.self) {
                        Text(self.raceDistances[$0])
                    }
                } .pickerStyle(MenuPickerStyle())
            }
        }
    }
       
       var trainingPeriodSection: some View {
           VStack(alignment: .leading, spacing: 10) {
               Text("Select training period for prediction")
                   .font(.title3)
                   .fontWeight(.bold)
               DatePicker("Beginning Date", selection: $begDate, in: ...Date(), displayedComponents: .date)
               DatePicker("End Date", selection: $endDate, in: ...Date(), displayedComponents: .date)
           }
       }
       
       var getPredictionButton: some View {
           Button("Get My Prediction") {
               getMyPrediction()
               // Track when a prediction is made
                          Analytics.logEvent("prediction_generated", parameters: [
                              "race_distance": raceDistances[selectedDistanceIndex],
                              "training_period_days": Calendar.current.dateComponents([.day], from: begDate, to: endDate).day ?? 0
                          ])
           }
           .buttonStyle(ProminentButtonStyle())
           
       }
    
        var paceUnitSection: some View {
              VStack(alignment: .leading, spacing: 5) {
                  Text("Select pace unit")
                      .font(.title3)
                      .fontWeight(.bold)
                  
                  Picker("Pace Unit", selection: $selectedPaceUnit) {
                      ForEach(paceUnits.indices, id: \.self) { index in
                            Text(paceUnits[index]).tag(index)
                        }
                    }
                .pickerStyle(SegmentedPickerStyle())
              }
          }
       
       var healthKitInfoLink: some View {
           NavigationLink(destination: HealthKitInfoView()) {
               HStack {
                   Image(systemName: "info.circle")
                       .imageScale(.medium)
                   Text("HealthKit Data Usage")
               }
               .foregroundColor(.gray)
           }
       }
       
    var resultsSection: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if let predictedTime = predictedTime, let requiredPace = requiredPace, errorMessage == nil {
                // Display prediction results
                VStack(spacing: 20) {
                    Text("\(raceDistances[selectedDistanceIndex]) Prediction")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(formatTime(predictedTime))
                        .font(.system(size: 58, weight: .heavy))
                        .foregroundColor(.green)
                    
                    Text("Pace Required")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(selectedPaceUnit == 1 ? formatPaceMetric(requiredPace) : formatPace(requiredPace))
                            .font(.system(size: 34, weight: .semibold))
                                            
                        Text(paceUnits[selectedPaceUnit])
                            .font(.system(size: 20))
                        }
                    .foregroundColor(.green)
                }
                .multilineTextAlignment(.center)
            } else if let errorMessage = errorMessage {
                // Display error message
                Text(errorMessage)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                // No data case
                Text("No running workouts found in the specified period.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
                        
            if !bestPerformanceDetails.isEmpty {
                Button(action: {
                    withAnimation {
                        showBestPerformanceDetails.toggle()
                    }
                }) {
                    Text(showBestPerformanceDetails ? "Hide Details" : "Show best workout performance used to calculate prediction")
                        .foregroundColor(.blue)
                        .font(.system(size: 15))
                }.padding(.top, 10)
                if showBestPerformanceDetails {
                    Text(bestPerformanceDetails)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .transition(.opacity)
                }
            }
            
            Spacer()
            
            // Conditional display of buttons
            if predictedTime != nil && requiredPace != nil && errorMessage == nil {
                // Display both buttons
                HStack(spacing: 20) {
                    Button(action: {
                        resetPrediction()
                    }) {
                        Text("New Prediction")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        self.showingShareSheet = true
                        shareResults() // log the analytics event

                    }) {
                        Text("Share Results")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showingShareSheet) {
                        ActivityView(activityItems: [self.shareMessage()])
                    }
                }
            } else {
                // Display only the "New Prediction" button
                Button(action: {
                    resetPrediction()
                }) {
                    Text("New Prediction")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            Link("Learn How This Works", destination: URL(string: "https://declankramper.notion.site/Race-Time-Predictor-App-6a485fdb13d84d07ab26e2aa7c3b2de0?pvs=4")!)
                .padding(.top, 10)
        }
        .padding()
    }
    
       
    var feedbackButton: some View {
            Button(action: {
                self.showingFeedbackView = true
            }) {
                Image(systemName: "info.circle")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .sheet(isPresented: $showingFeedbackView) {
                FeedbackView()
            }
        }
    
    private func getMyPrediction() {
        HealthKitManager.shared.requestAuthorization { success, error in
            guard success else {
                DispatchQueue.main.async {
                    self.predictedTime = nil
                    self.requiredPace = nil
                    self.errorMessage = "Error: \(error?.localizedDescription ?? "Could not access HealthKit data.")"
                    self.showingResults = true
                    
                    // Log failed prediction attempt
                    Analytics.logEvent("prediction_generated", parameters: [
                        "race_distance": raceDistances[selectedDistanceIndex],
                        "training_period_days": Calendar.current.dateComponents([.day], from: begDate, to: endDate).day ?? 0,
                        "success": false,
                        "error_type": "healthkit_authorization",
                        "error_message": error?.localizedDescription ?? "Could not access HealthKit data"
                    ])
                }
                return
            }
            
            HealthKitManager.shared.getRunningWorkouts(begDate: self.begDate, endDate: self.endDate) { performances in
                let result = HealthKitManager.shared.findBestPerformance(workouts: performances, predictDistance: self.predictDistances[self.selectedDistanceIndex] * 1000)
                
                DispatchQueue.main.async {
                    if let bestPerformance = result.bestPerformance, let lowestPredictedTime = result.lowestPredictedTime {
                        self.predictedTime = lowestPredictedTime
                        self.shareTime = self.formatTime(lowestPredictedTime)
                        self.bestPerformanceDetails = """
                        Date: \(bestPerformance.date.formatted(date: .abbreviated, time: .omitted))
                        Time: \(formatTime(bestPerformance.time))
                        Distance: \(formatDistance(bestPerformance.distance)) miles
                        """
                        
                        // Calculate pace in minutes per mile
                        let predictedDistanceMiles = (self.predictDistances[self.selectedDistanceIndex] * 1000) * 0.000621371
                        let pace = lowestPredictedTime / 60.0 / predictedDistanceMiles
                        self.requiredPace = pace
                        self.errorMessage = nil
                        
                        // Log successful prediction
                        Analytics.logEvent("prediction_generated", parameters: [
                            "race_distance": raceDistances[selectedDistanceIndex],
                            "training_period_days": Calendar.current.dateComponents([.day], from: begDate, to: endDate).day ?? 0,
                            "success": true,
                            "predicted_time": self.shareTime,
                            "required_pace": formatPace(pace)
                        ])
                    } else {
                        self.predictedTime = nil
                        self.requiredPace = nil
                        self.errorMessage = "No running workouts found in the specified period."
                        
                        // Log failed prediction due to no data
                        Analytics.logEvent("prediction_generated", parameters: [
                            "race_distance": raceDistances[selectedDistanceIndex],
                            "training_period_days": Calendar.current.dateComponents([.day], from: begDate, to: endDate).day ?? 0,
                            "success": false,
                            "error_type": "no_workouts",
                            "error_message": "No running workouts found in the specified period"
                        ])
                    }
                    self.showingResults = true
                }
            }
        }
    }
    
    
    private func resetPrediction() {
            self.showingResults = false
            self.selectedDistanceIndex = 0
            self.predictedTime = nil
            self.requiredPace = nil
            self.errorMessage = nil
            self.shareTime = "[null]"
            self.bestPerformanceDetails = ""
            self.showBestPerformanceDetails = false
        }
    
    // Helper functions
        private func formatTime(_ time: TimeInterval) -> String {
            let hours = Int(time) / 3600
            let minutes = (Int(time) % 3600) / 60
            let seconds = Int(time) % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
        
        private func formatPace(_ pace: Double) -> String {
            let paceMinutes = Int(pace)
            let paceSeconds = Int((pace - Double(paceMinutes)) * 60.0 + 0.5)
            return String(format: "%d:%02d", paceMinutes, paceSeconds)
        }
    
        private func formatPaceMetric(_ pace: Double) -> String {
               // Convert min/mile to min/km (1 mile = 1.60934 kilometers)
               let pacePerKm = pace / 1.60934
               let paceMinutes = Int(pacePerKm)
               let paceSeconds = Int((pacePerKm - Double(paceMinutes)) * 60.0 + 0.5)
               return String(format: "%d:%02d", paceMinutes, paceSeconds)
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
                
                Text("Please ensure (1) you've allowed access to your HealthKit workout data and (2) there are running workouts in your Apple Heath App to get results.")
                
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
                           .clipShape(RoundedRectangle(cornerRadius: 10))
                           .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                           .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
                       Spacer() // Add a Spacer to the right side
                   }
            .background(Color.clear) // Ensure the HStack background is clear

        }
    }
    // Track when results are shared
    private func shareResults() {
        Analytics.logEvent("results_shared", parameters: [
                "race_distance": raceDistances[selectedDistanceIndex],
                "predicted_time": shareTime,
                "training_period_days": Calendar.current.dateComponents([.day], from: begDate, to: endDate).day ?? 0,
                "has_error": errorMessage != nil,
        ])
    }
}


// preview in canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

