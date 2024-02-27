import SwiftUI

struct FeedbackView: View {
    @State private var showFormulaAssumptions: Bool = false
    @State private var featureFeedback: String = ""
    @State private var satisfactionRating: Int = 3 // Default to mid-scale
    let satisfactionOptions = [1, 2, 3, 4, 5]

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
                    TextField("Your feedback", text: $featureFeedback)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("How satisfied are you with our product/service?")
                    Picker("Satisfaction", selection: $satisfactionRating) {
                        ForEach(satisfactionOptions, id: \.self) { number in
                            Text("\(number)")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button(action: {
                        submitFeedback()
                    }) {
                        Text("Submit")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Section(header: Text("Credits")) {
                    Text("@dkbuilds")
                    Text("declankramper.me")
                    Text("built feb '24")
                }
            }
            .navigationBarTitle("About", displayMode: .inline)
            .listStyle(SidebarListStyle())
        }
    }
    func submitFeedback() {
            // Handle the submit action
            
        }
}
