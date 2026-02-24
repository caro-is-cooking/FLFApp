import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var goals: UserGoals?
    @Published var hasCompletedOnboarding: Bool = false
    @Published var dailyLogs: [String: DailyLog] = [:]
    @Published var chatHistory: [ChatMessage] = []
    @Published var userChallenges: [String] = []  // things user finds challenging, for chat context
    
    private let store = DataStore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        load()
    }
    
    var weeklyCalorieTarget: Double {
        goals?.weeklyCalorieTarget ?? 0
    }
    
    var goalWeightLbs: Double {
        goals?.goalWeightLbs ?? 0
    }
    
    func setGoalWeight(_ lbs: Double) {
        goals = UserGoals(goalWeightLbs: lbs)
        hasCompletedOnboarding = true
        save()
    }
    
    func updateGoalWeight(_ lbs: Double) {
        goals = UserGoals(goalWeightLbs: lbs)
        save()
    }
    
    func logOrUpdate(_ log: DailyLog) {
        dailyLogs[log.dateKey] = log
        save()
    }
    
    func logFor(date: Date) -> DailyLog? {
        dailyLogs[DailyLog.dateKey(from: date)]
    }
    
    /// Calendar week containing the given date (e.g. Sunday–Saturday in US locale; follows device calendar).
    /// Not a rolling 7-day window.
    func logsForWeek(containing date: Date) -> [DailyLog] {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else { return [] }
        return (0..<7).compactMap { dayOffset in
            guard let d = cal.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
            return dailyLogs[DailyLog.dateKey(from: d)]
        }
    }
    
    func caloriesConsumedThisWeek(upTo date: Date) -> Double {
        logsForWeek(containing: date).compactMap(\.caloriesConsumed).reduce(0, +)
    }
    
    func caloriesRemainingThisWeek(asOf date: Date) -> Double {
        max(0, weeklyCalorieTarget - caloriesConsumedThisWeek(upTo: date))
    }
    
    func addChatMessage(_ message: ChatMessage) {
        chatHistory.append(message)
        save()
    }
    
    func addUserChallenge(_ challenge: String) {
        if !userChallenges.contains(challenge) {
            userChallenges.append(challenge)
            save()
        }
    }
    
    private func load() {
        goals = store.loadGoals()
        hasCompletedOnboarding = store.loadOnboardingComplete()
        dailyLogs = store.loadDailyLogs()
        chatHistory = store.loadChatHistory()
        userChallenges = store.loadUserChallenges()
    }
    
    private func save() {
        if let g = goals { store.saveGoals(g) }
        store.saveOnboardingComplete(hasCompletedOnboarding)
        store.saveDailyLogs(dailyLogs)
        store.saveChatHistory(chatHistory)
        store.saveUserChallenges(userChallenges)
    }
}
