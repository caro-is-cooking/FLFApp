import SwiftUI

struct FoodTrackerView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddFood = false
    @State private var entryToEdit: FoodEntry?

    private var todayKey: String {
        DailyLog.dateKey(from: Date())
    }

    private var todayEntries: [FoodEntry] {
        appState.foodEntries(for: todayKey)
    }

    private var todayTotalCal: Double {
        todayEntries.map(\.calories).reduce(0, +)
    }

    private var todayTotalProtein: Double {
        todayEntries.map(\.proteinGrams).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's total")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            Text("\(Int(todayTotalCal)) cal · \(Int(todayTotalProtein))g protein")
                                .font(.title2.weight(.medium))
                        }
                        Spacer()
                        if appState.goalWeightLbs > 0 {
                            Text("Goal: \(Int(appState.goalWeightLbs))g protein")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        showAddFood = true
                    } label: {
                        Label("Add food", systemImage: "plus.circle.fill")
                    }

                    ForEach(todayEntries) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(Int(entry.calories)) cal · \(Int(entry.proteinGrams))g protein")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            Button {
                                entryToEdit = entry
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.body)
                            }
                            .buttonStyle(.borderless)
                            Button(role: .destructive) {
                                appState.removeFoodEntry(id: entry.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.body)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Today's log")
                }
            }
            .navigationTitle("Food")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Sync to Overview") {
                        appState.syncTodayFoodToOverview()
                    }
                    .disabled(todayEntries.isEmpty)
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodView(todayKey: todayKey)
            }
            .sheet(item: $entryToEdit) { entry in
                EditFoodEntryView(
                    entry: entry,
                    onSave: { name, calories, protein in
                        appState.updateFoodEntry(id: entry.id, name: name, calories: calories, proteinGrams: protein)
                        entryToEdit = nil
                    },
                    onCancel: { entryToEdit = nil }
                )
            }
        }
    }
}

// MARK: - Edit food entry (name, calories, quantity/protein)
struct EditFoodEntryView: View {
    let entry: FoodEntry
    let onSave: (String, Double, Double) -> Void
    let onCancel: () -> Void

    @State private var nameText: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $nameText)
                    TextField("Calories", text: $caloriesText)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $proteinText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Edit entry")
                } footer: {
                    Text("Change the amount or fix a mistake. Totals will update automatically.")
                }
            }
            .navigationTitle("Edit food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                nameText = entry.name
                caloriesText = entry.calories == floor(entry.calories) ? "\(Int(entry.calories))" : String(format: "%.1f", entry.calories)
                proteinText = entry.proteinGrams == floor(entry.proteinGrams) ? "\(Int(entry.proteinGrams))" : String(format: "%.1f", entry.proteinGrams)
            }
        }
    }

    private var isValid: Bool {
        guard !nameText.trimmingCharacters(in: .whitespaces).isEmpty,
              let cal = Double(caloriesText.trimmingCharacters(in: .whitespaces)),
              let pro = Double(proteinText.trimmingCharacters(in: .whitespaces)) else { return false }
        return cal >= 0 && pro >= 0
    }

    private func save() {
        let name = nameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty,
              let cal = Double(caloriesText.trimmingCharacters(in: .whitespaces)),
              let pro = Double(proteinText.trimmingCharacters(in: .whitespaces)),
              cal >= 0, pro >= 0 else { return }
        onSave(name, cal, pro)
        dismiss()
    }
}

#Preview {
    FoodTrackerView()
        .environmentObject(AppState())
}
