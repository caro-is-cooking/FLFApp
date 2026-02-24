import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var goalWeightText: String = ""
    @State private var showError = false
    @FocusState private var focused: Bool
    
    var weeklyCalories: Double? {
        guard let lbs = Double(goalWeightText.trimmingCharacters(in: .whitespaces)), lbs > 0 else { return nil }
        return lbs * 84
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text("FLF")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Set your goal weight to get your weekly calorie target.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal weight (lbs)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g. 150", text: $goalWeightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused)
                }
                .padding(.horizontal, 24)
                
                if let weekly = weeklyCalories {
                    VStack(spacing: 4) {
                        Text("Weekly calorie target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(weekly)) cal/week")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
                
                Button(action: saveGoal) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .disabled(weeklyCalories == nil)
                
                Spacer()
            }
            .padding(.top, 40)
            .alert("Invalid weight", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid goal weight in pounds.")
            }
        }
    }
    
    private func saveGoal() {
        guard let lbs = Double(goalWeightText.trimmingCharacters(in: .whitespaces)), lbs > 0 else {
            showError = true
            return
        }
        appState.setGoalWeight(lbs)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
