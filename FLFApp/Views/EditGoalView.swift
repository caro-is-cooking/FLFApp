import SwiftUI

struct EditGoalView: View {
    let currentGoalWeight: Double
    let onSave: (Double) -> Void
    let onCancel: () -> Void
    
    @State private var goalWeightText: String = ""
    @State private var showError = false
    
    private var weeklyCalories: Double? {
        guard let lbs = Double(goalWeightText.trimmingCharacters(in: .whitespaces)), lbs > 0 else { return nil }
        return lbs * 84
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal weight (lbs)", text: $goalWeightText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Goal weight")
                } footer: {
                    Text("Weekly calorie target = goal weight × 84.")
                }
                if let weekly = weeklyCalories {
                    Section("New weekly target") {
                        Text("\(Int(weekly)) cal/week")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(weeklyCalories == nil)
                }
            }
            .onAppear {
                goalWeightText = currentGoalWeight > 0 ? String(format: "%.1f", currentGoalWeight) : ""
            }
            .alert("Invalid weight", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid goal weight in pounds.")
            }
        }
    }
    
    private func save() {
        guard let lbs = Double(goalWeightText.trimmingCharacters(in: .whitespaces)), lbs > 0 else {
            showError = true
            return
        }
        onSave(lbs)
    }
}
