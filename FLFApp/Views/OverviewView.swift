import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditor = false
    @State private var showEditGoal = false
    @State private var editingLog: DailyLog?
    
    private let calendar = Calendar.current
    private var weekTarget: Double { appState.weeklyCalorieTarget }
    private var weekConsumed: Double { appState.caloriesConsumedThisWeek(upTo: Date()) }
    private var weekRemaining: Double { appState.caloriesRemainingThisWeek(asOf: Date()) }
    private var todayLog: DailyLog? { appState.logFor(date: Date()) }
    private var todayCalories: Double { todayLog?.caloriesConsumed ?? 0 }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Weekly summary card
                    weeklySummaryCard
                    
                    // Today's numbers
                    todayCard
                    
                    // Time series list (recent days)
                    timeSeriesSection
                }
                .padding()
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit goal") {
                        showEditGoal = true
                    }
                }
            }
            .sheet(isPresented: $showEditGoal) {
                EditGoalView(currentGoalWeight: appState.goalWeightLbs) { newWeight in
                    appState.updateGoalWeight(newWeight)
                    showEditGoal = false
                } onCancel: {
                    showEditGoal = false
                }
            }
            .sheet(isPresented: $showEditor) {
                if let log = editingLog {
                    LogEditorView(log: log) { updated in
                        appState.logOrUpdate(updated)
                        showEditor = false
                        editingLog = nil
                    } onCancel: {
                        showEditor = false
                        editingLog = nil
                    }
                    .environmentObject(appState)
                }
            }
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week")
                .font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Consumed")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text("\(Int(weekConsumed)) cal")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Text("\(Int(weekTarget)) cal")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            Text("Calories left this week: \(Int(weekRemaining))")
                .font(.subheadline)
                .foregroundStyle(weekRemaining > 0 ? Color.secondary : Color.red)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    let key = DailyLog.dateKey(from: Date())
                    editingLog = appState.dailyLogs[key] ?? DailyLog(dateKey: key)
                    showEditor = true
                }
            }
            HStack(spacing: 16) {
                metricBlock(title: "Calories", value: "\(Int(todayCalories))")
                metricBlock(title: "Protein (g)", value: "\(Int(todayLog?.proteinGrams ?? 0))")
                metricBlock(title: "Steps", value: "\(todayLog?.stepCount ?? 0)")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func metricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var timeSeriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent days")
                .font(.headline)
            ForEach(recentDates, id: \.self) { date in
                let key = DailyLog.dateKey(from: date)
                let log = appState.dailyLogs[key] ?? DailyLog(dateKey: key)
                Button {
                    editingLog = log
                    showEditor = true
                } label: {
                    DayRowView(date: date, log: log)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var recentDates: [Date] {
        (0..<14).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date()))
        }
    }
}

struct DayRowView: View {
    let date: Date
    let log: DailyLog
    
    private static var shortDate: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE M/d"
        return f
    }
    
    var body: some View {
        HStack {
            Text(Self.shortDate.string(from: date))
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            Text("\(Int(log.caloriesConsumed ?? 0)) cal")
                .font(.subheadline)
                .frame(width: 70, alignment: .trailing)
            Text("\(Int(log.proteinGrams ?? 0)) g protein")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .frame(width: 90, alignment: .trailing)
            Text("\(log.stepCount ?? 0) steps")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
            if let w = log.weightLbs {
                Text(String(format: "%.1f lbs", w))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    OverviewView()
        .environmentObject(AppState())
}
