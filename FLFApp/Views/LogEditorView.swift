import SwiftUI

struct LogEditorView: View {
    let log: DailyLog
    let onSave: (DailyLog) -> Void
    let onCancel: () -> Void

    @EnvironmentObject var appState: AppState
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var stepsText: String

    init(log: DailyLog, onSave: @escaping (DailyLog) -> Void, onCancel: @escaping () -> Void) {
        self.log = log
        self.onSave = onSave
        self.onCancel = onCancel
        _caloriesText = State(initialValue: log.caloriesConsumed.map { "\(Int($0))" } ?? "")
        _proteinText = State(initialValue: log.proteinGrams.map { String(format: "%.0f", $0) } ?? "")
        _stepsText = State(initialValue: log.stepCount.map { "\($0)" } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Calories") {
                    TextField("Calories consumed", text: $caloriesText)
                        .keyboardType(.decimalPad)
                }
                Section("Protein (grams)") {
                    TextField("Protein", text: $proteinText)
                        .keyboardType(.decimalPad)
                }
                Section("Steps") {
                    TextField("Step count", text: $stepsText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }
    
    private func save() {
        var updated = log
        updated.caloriesConsumed = Double(caloriesText.trimmingCharacters(in: .whitespaces))
        updated.proteinGrams = Double(proteinText.trimmingCharacters(in: .whitespaces))
        updated.stepCount = Int(stepsText.trimmingCharacters(in: .whitespaces))
        // Weight is edited only in the Weigh In tab; leave existing value unchanged
        updated.isManualOverride = true
        onSave(updated)
    }
}
