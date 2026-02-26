import SwiftUI

struct AddFoodView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let todayKey: String

    @State private var searchText = ""
    @State private var showCustomEntry = false
    @State private var selectedFood: SearchableFoodItem?
    @State private var showAmountPicker = false

    private var searchResults: [SearchableFoodItem] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        var items: [SearchableFoodItem] = []
        if q.isEmpty {
            items = CommonFoods.all.map { .common($0) } + appState.userAddedFoods.map { .user($0) }
        } else {
            items = CommonFoods.search(searchText).map { .common($0) }
                + appState.userAddedFoods.filter { $0.name.lowercased().contains(q) }.map { .user($0) }
        }
        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showCustomEntry = true
                    } label: {
                        Label("Add custom food (saved for next time)", systemImage: "square.and.pencil")
                    }
                }

                Section {
                    ForEach(searchResults, id: \.id) { item in
                        Button {
                            selectedFood = item
                            showAmountPicker = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.primary)
                                    Text("\(Int(item.caloriesPer100g)) cal / 100g · \(Int(item.proteinPer100g))g protein")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.accentColor)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Foods")
                }
            }
            .searchable(text: $searchText, prompt: "Search foods")
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomEntry) {
                CustomFoodView(todayKey: todayKey) { newFood in
                    appState.addUserAddedFood(newFood)
                    showCustomEntry = false
                    dismiss()
                }
            }
            .sheet(item: $selectedFood) { item in
                FoodAmountPickerView(food: item, todayKey: todayKey) { entry in
                    appState.addFoodEntry(entry)
                    selectedFood = nil
                    dismiss()
                }
            }
        }
    }
}

// So we can use .sheet(item:)
extension SearchableFoodItem: @retroactive Hashable {
    static func == (lhs: SearchableFoodItem, rhs: SearchableFoodItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct FoodAmountPickerView: View {
    let food: SearchableFoodItem
    let todayKey: String
    let onAdd: (FoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = "100"
    @State private var selectedUnit: FoodAmountUnit = .grams

    private var availableUnits: [FoodAmountUnit] {
        var u: [FoodAmountUnit] = [.grams, .ounces]
        if food.canUseCup { u.append(.cup) }
        if food.canUseServing { u.append(.serving) }
        return u
    }

    private var computedGrams: Double? {
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return food.grams(from: amount, unit: selectedUnit)
    }

    private var previewCalories: Double {
        guard let g = computedGrams, g > 0 else { return 0 }
        return food.calories(forGrams: g)
    }

    private var previewProtein: Double {
        guard let g = computedGrams, g > 0 else { return 0 }
        return food.protein(forGrams: g)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(availableUnits) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(food.name)
                }
                if computedGrams != nil && (computedGrams ?? 0) > 0 {
                    Section {
                        Text("\(Int(previewCalories)) cal · \(Int(previewProtein))g protein")
                            .font(.headline)
                    } header: {
                        Text("This serving")
                    }
                }
            }
            .navigationTitle("Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addEntry()
                    }
                    .disabled(computedGrams == nil || (computedGrams ?? 0) <= 0)
                }
            }
        }
    }

    private func addEntry() {
        guard let g = computedGrams, g > 0 else { return }
        let unitLabel = selectedUnit == .serving ? "serving" : selectedUnit.rawValue
        let entry = FoodEntry(
            dateKey: todayKey,
            name: "\(food.name) (\(amountText) \(unitLabel))",
            calories: food.calories(forGrams: g),
            proteinGrams: food.protein(forGrams: g)
        )
        onAdd(entry)
        dismiss()
    }
}

struct CustomFoodView: View {
    @Environment(\.dismiss) private var dismiss
    let todayKey: String
    let onSave: (UserAddedFood) -> Void

    @State private var name = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var perOption: Int = 0 // 0 = 100g, 1 = 1 cup, 2 = 1 serving
    @State private var gramsForUnitText = "" // for cup or serving

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Food name", text: $name)
                    TextField("Calories", text: $caloriesText)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $proteinText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Nutrition")
                }
                Section {
                    Picker("This is per", selection: $perOption) {
                        Text("100 g").tag(0)
                        Text("1 cup").tag(1)
                        Text("1 serving").tag(2)
                    }
                    .pickerStyle(.segmented)
                    if perOption == 1 || perOption == 2 {
                        TextField(perOption == 1 ? "Grams per 1 cup" : "Grams per 1 serving", text: $gramsForUnitText)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Amount")
                } footer: {
                    Text("Saved foods appear in search so you can log them anytime with any amount (g, oz, cup).")
                }
            }
            .navigationTitle("New food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || caloriesText.isEmpty)
                }
            }
        }
    }

    private func save() {
        let cal = Double(caloriesText.trimmingCharacters(in: .whitespaces)) ?? 0
        let protein = Double(proteinText.trimmingCharacters(in: .whitespaces)) ?? 0
        let gramsForUnit = Double(gramsForUnitText.trimmingCharacters(in: .whitespaces)) ?? 100

        var caloriesPer100g: Double
        var proteinPer100g: Double
        var gramsPerCup: Double?
        var gramsPerServing: Double?

        if perOption == 0 {
            caloriesPer100g = cal
            proteinPer100g = protein
        } else {
            guard gramsForUnit > 0 else { return }
            caloriesPer100g = (cal / gramsForUnit) * 100
            proteinPer100g = (protein / gramsForUnit) * 100
            if perOption == 1 { gramsPerCup = gramsForUnit }
            else { gramsPerServing = gramsForUnit }
        }

        let newFood = UserAddedFood(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            gramsPerCup: gramsPerCup,
            gramsPerServing: gramsPerServing
        )
        onSave(newFood)
        dismiss()
    }
}

#Preview {
    AddFoodView(todayKey: DailyLog.dateKey(from: Date()))
        .environmentObject(AppState())
}
