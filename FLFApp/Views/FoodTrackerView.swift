import SwiftUI

struct FoodTrackerView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddFood = false

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
        }
    }
}

#Preview {
    FoodTrackerView()
        .environmentObject(AppState())
}
