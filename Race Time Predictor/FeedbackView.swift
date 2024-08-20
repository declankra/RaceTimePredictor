import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct FeedbackView: View {
    @State private var showFormulaAssumptions: Bool = false
    @State private var featureExpected: String = ""
    @State private var featureMagic: String = ""
    @State private var satisfactionRating: Int = 5  // Default to mid-scale
    let satisfactionOptions = [1, 2, 3, 4, 5, 6, 8, 9, 10]
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: $showFormulaAssumptions) {
                        Text(showFormulaAssumptions ? "Assumptions " : "Show formula assumptions")
                    }
                    
                    if showFormulaAssumptions {
                        VStack(alignment: .leading) {
                            Text("1. It is assumed that a runner has completed the necessary training for the distance they decide to run. A strong performance on the 10km course the day before does not imply that you can run a half-marathon in 1h 30 minutes today. ")
                            Text("2. Assumes that an athlete does not have a solid inherent aptitude for speed or endurance. Some people will always do better than others regardless of how much they train.")
                            Text("3. The computations are less precise for times less than 3.5 minutes and more than 4 hours.")
                        }
                        .transition(.slide)
                    }
                    
                }
                
                Section(header: Text("Give feedback")) {
                    Text("What feature did you expect in the product but did not find?")
                    TextField("I expected...", text: $featureExpected)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("If you could magically add one feature, what would it do?")
                    TextField("It would...", text: $featureMagic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("How satisfied are you with the product?")
                    Picker("Satisfaction", selection: $satisfactionRating) {
                        ForEach(satisfactionOptions, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button(action: {
                        submitFeedback()
                    }) {
                        Text("Submit Feedback")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertMessage))
                    }
                }
                
                Section(header: Text("Credits")) {
                    Text("@dkbuilds")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            openEmail()
                        }
                    Link("declankramper.me", destination: URL(string: "https://declankramper.me")!)
                        .foregroundColor(.blue)
                    Link("built feb '24", destination: URL(string: "https://declankramper.notion.site/Race-Time-Predictor-App-6a485fdb13d84d07ab26e2aa7c3b2de0?pvs=4")!)
                        .foregroundColor(.blue)
                }
            }
                .navigationBarTitle("About", displayMode: .inline)
                .listStyle(SidebarListStyle())
            }
        }
    
    // model to represent the feedback data that is actually sent to firebase (grouped out for clarity)
    struct Feedback: Codable {
        var featureExpected: String
        var featureMagic: String
        var satisfactionRating: Int
        var timestamp: Date = Date()
        
        var dictionary: [String: Any] {
            return [
                "featureExpected": featureExpected,
                "featureMagic": featureMagic,
                "satisfactionRating": satisfactionRating,
                "timestamp": timestamp
            ]
        }
    }
        
    func submitFeedback() {
        if featureExpected.isEmpty || featureMagic.isEmpty {
            alertMessage = "Please fill out all feedback fields"
            showAlert = true
        } else {
            let feedback = Feedback(
                featureExpected: featureExpected,
                featureMagic: featureMagic,
                satisfactionRating: satisfactionRating
            )
            let db = Firestore.firestore()
                        db.collection("feedback").addDocument(data: feedback.dictionary) { error in
                            if let error = error {
                                alertMessage = "Error submitting feedback: \(error.localizedDescription)"
                            } else {
                                alertMessage = "I truly value your feedback - Thank you very much!!"
                                featureExpected = ""
                                featureMagic = ""
                                satisfactionRating = 5 // Reset to default value
                            }
                            showAlert = true
                        }
            
        }
    }
        
        func openEmail() {
            let email = "declankramper@gmail.com"
            if let emailURL = URL(string: "mailto:\(email)") {
                if UIApplication.shared.canOpenURL(emailURL) {
                    UIApplication.shared.open(emailURL, options: [:], completionHandler: nil)
                } else {
                    print("Cannot open email client")
                }
            }
        }

    }

struct FeedbackView_Previews: PreviewProvider {
            static var previews: some View {
                FeedbackView()
            }
        }
