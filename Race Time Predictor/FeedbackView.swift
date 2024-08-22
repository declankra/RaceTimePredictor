import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct FeedbackView: View {
    @State private var showFormulaAssumptions: Bool = false
    @State private var featureExpected: String = ""
    @State private var featureMagic: String = ""
    @State private var satisfactionRating: Int = 5
    let satisfactionOptions = [1, 2, 3, 4, 5, 6, 8, 9, 10]
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @FocusState private var focusedField: FocusField?
    
    enum FocusField: Hashable {
        case expected, magic
    }
    
    // body variable >> view for all three section variables included
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 50) {
                    assumptionsSection
                    feedbackSection
                    creditsSection
                }
                .padding()
            }
            .navigationBarTitle("About", displayMode: .inline)
            .onAppear {
                preloadKeyboard()
            }
        }
    }
    
    // variable >> view for assumptions
    var assumptionsSection: some View {
           VStack(alignment: .leading) {
               HStack {
                   Text("Formula Assumptions")
                       .font(.title3)
                       .fontWeight(.bold)
                   
                   Spacer()  // Pushes the toggle to the far right
                   
                   Toggle(isOn: $showFormulaAssumptions.animation()) {
                       Text(showFormulaAssumptions ? "Hide" : "Show")
                   }
                   .labelsHidden()  // Hides the default label to only show the switch
               }
               .padding(.bottom, 5)
               
               if showFormulaAssumptions {
                   VStack(alignment: .leading, spacing: 10) {
                       Text("1. It is assumed that a runner has completed the necessary training for the distance they decide to run.")
                       Text("2. Assumes that an athlete does not have a solid inherent aptitude for speed or endurance.")
                       Text("3. The computations are less precise for times less than 3.5 minutes and more than 4 hours.")
                   }
                   .transition(.opacity)
               }
           }
       }

    
    // variable >> view for feedback
    var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Give feedback")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            Text("What feature did you expect in the product but did not find?")
            TextField("I expected...", text: $featureExpected)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .expected)
            
            Text("If you could magically add one feature, what would it do?")
            TextField("It would...", text: $featureMagic)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .magic)
            
            Text("How satisfied are you with the product?")
            Picker("Satisfaction", selection: $satisfactionRating) {
                ForEach(satisfactionOptions, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                           Spacer()
                           Button(action: submitFeedback) {
                               Text("Submit Feedback")
                                   .frame(width: UIScreen.main.bounds.width * 0.6)  // Set a specific width
                                   .padding()
                                   .background(Color.blue)
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                           }
                           Spacer()
                       }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMessage))
        }
    }
    
    // variable >> view for credits
    var creditsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Credits")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            Button(action: openEmail) {
                Text("@dkbuilds")
                .foregroundColor(.blue)
            }
            
            Link("declankramper.me", destination: URL(string: "https://declankramper.me")!)
                .foregroundColor(.blue)
            
            Link("built feb '24", destination: URL(string: "https://declankramper.notion.site/Race-Time-Predictor-App-6a485fdb13d84d07ab26e2aa7c3b2de0?pvs=4")!)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        hideKeyboard()
    }
        
    func openEmail() {
            let email = "declankramper@gmail.com"
            if let emailURL = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(emailURL, options: [:], completionHandler: nil)
            }
        }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    
    private func preloadKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let dummyTextField = UITextField()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(dummyTextField)
                dummyTextField.becomeFirstResponder()
                dummyTextField.resignFirstResponder()
                dummyTextField.removeFromSuperview()
            }
        }
    }

    }

    
struct FeedbackView_Previews: PreviewProvider {
            static var previews: some View {
                FeedbackView()
            }
        }





/* possible fix for keyboard lag on textfield: <0x12015d540> Gesture: System gesture gate timed out.

.onTapGesture {
DispatchQueue.main.async {
    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
}
}
 
*/
