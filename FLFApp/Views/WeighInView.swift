import SwiftUI
import Charts

enum WeightTimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case all = "All"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .month
        case .threeMonths: return .month
        case .all: return .year
        }
    }
    
    var value: Int {
        switch self {
        case .week: return 7
        case .month: return 1
        case .threeMonths: return 3
        case .all: return 10
        }
    }
}

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weightLbs: Double
}

struct WeighInView: View {
    @EnvironmentObject var appState: AppState
    @State private var weightText: String = ""
    @State private var savedMessage: String?
    @State private var selectedRange: WeightTimeRange = .month
    @FocusState private var focused: Bool
    
    private var todayKey: String { DailyLog.dateKey(from: Date()) }
    
    private var allWeightPoints: [WeightDataPoint] {
        let cal = Calendar.current
        return appState.dailyLogs
            .compactMap { (key, log) -> WeightDataPoint? in
                guard let w = log.weightLbs, let date = DailyLog.dateFormatter.date(from: key) else { return nil }
                return WeightDataPoint(date: cal.startOfDay(for: date), weightLbs: w)
            }
            .sorted { $0.date < $1.date }
    }
    
    private var filteredWeightPoints: [WeightDataPoint] {
        let cal = Calendar.current
        let now = Date()
        let start: Date? = switch selectedRange {
        case .week:
            cal.date(byAdding: .day, value: -7, to: now)
        case .month:
            cal.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            cal.date(byAdding: .month, value: -3, to: now)
        case .all:
            nil
        }
        guard let start = start else { return allWeightPoints }
        return allWeightPoints.filter { $0.date >= start }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Chart section
                    if !allWeightPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress")
                                .font(.headline)
                            Picker("Range", selection: $selectedRange) {
                                ForEach(WeightTimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            chartView
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Log weight
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Log your morning weight")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        TextField("Weight (lbs)", text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .focused($focused)
                        if let msg = savedMessage {
                            Text(msg)
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        Button(action: saveWeight) {
                            Text("Save weight")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(Double(weightText.trimmingCharacters(in: .whitespaces)) == nil)
                    }
                    
                    recentWeighIns
                }
                .padding()
            }
            .navigationTitle("Weigh In")
            .onAppear {
                if let log = appState.dailyLogs[todayKey], let w = log.weightLbs {
                    weightText = String(format: "%.1f", w)
                }
            }
        }
    }
    
    private var chartView: some View {
        Group {
            if filteredWeightPoints.isEmpty {
                Text("No data for this range. Log weights to see your trend.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            } else {
                Chart(filteredWeightPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weightLbs)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weightLbs)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(30)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(6, filteredWeightPoints.count))) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
                }
                .frame(height: 200)
            }
        }
    }
    
    private func saveWeight() {
        guard let lbs = Double(weightText.trimmingCharacters(in: .whitespaces)), lbs > 0 else { return }
        var log = appState.dailyLogs[todayKey] ?? DailyLog(dateKey: todayKey)
        log.weightLbs = lbs
        log.isManualOverride = true
        appState.logOrUpdate(log)
        savedMessage = "Weight saved."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedMessage = nil
        }
    }
    
    private var recentWeighIns: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent weigh-ins")
                .font(.headline)
            ForEach(recentDatesWithWeight, id: \.dateKey) { item in
                HStack {
                    Text(shortDate(item.date))
                        .font(.subheadline)
                    Spacer()
                    if let w = item.weightLbs {
                        Text(String(format: "%.1f lbs", w))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, 8)
    }
    
    private var recentDatesWithWeight: [(dateKey: String, date: Date, weightLbs: Double?)] {
        let cal = Calendar.current
        return (0..<7).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date())) else { return nil }
            let key = DailyLog.dateKey(from: date)
            let log = appState.dailyLogs[key]
            return (dateKey: key, date: date, weightLbs: log?.weightLbs)
        }
    }
    
    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE M/d"
        return f.string(from: date)
    }
}

#Preview {
    WeighInView()
        .environmentObject(AppState())
}
