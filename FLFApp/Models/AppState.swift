import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var goals: UserGoals?
    @Published var hasCompletedOnboarding: Bool = false
    @Published var dailyLogs: [String: DailyLog] = [:]
    @Published var chatHistory: [ChatMessage] = []
    @Published var userChallenges: [String] = []  // things user finds challenging, for chat context
    @Published var foodEntries: [FoodEntry] = []
    @Published var userAddedFoods: [UserAddedFood] = []
    @Published var appliedFoodLogSuggestions: Set<String> = []

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
    
    /// Saves a chat image and returns the relative path to store on the message.
    func saveChatImage(id: UUID, jpegData: Data) -> String {
        store.saveChatImage(id: id, jpegData: jpegData)
    }
    
    /// Loads chat image data for display (e.g. from message.attachmentImagePath).
    func loadChatImageData(relativePath: String) -> Data? {
        store.loadChatImageData(relativePath: relativePath)
    }
    
    func addUserChallenge(_ challenge: String) {
        if !userChallenges.contains(challenge) {
            userChallenges.append(challenge)
            save()
        }
    }

    func addFoodEntry(_ entry: FoodEntry) {
        foodEntries.append(entry)
        save()
    }

    func removeFoodEntry(id: String) {
        foodEntries.removeAll { $0.id == id }
        save()
    }

    func updateFoodEntry(id: String, name: String, calories: Double, proteinGrams: Double) {
        guard let idx = foodEntries.firstIndex(where: { $0.id == id }) else { return }
        foodEntries[idx].name = name
        foodEntries[idx].calories = calories
        foodEntries[idx].proteinGrams = proteinGrams
        save()
    }

    func addUserAddedFood(_ food: UserAddedFood) {
        if !userAddedFoods.contains(where: { $0.id == food.id }) {
            userAddedFoods.append(food)
            save()
        }
    }

    func removeUserAddedFood(id: String) {
        userAddedFoods.removeAll { $0.id == id }
        save()
    }

    func foodEntries(for dateKey: String) -> [FoodEntry] {
        foodEntries.filter { $0.dateKey == dateKey }
    }

    /// Totals for a given day from food tracker.
    func foodTotals(for dateKey: String) -> (calories: Double, protein: Double) {
        let entries = foodEntries(for: dateKey)
        let cal = entries.map(\.calories).reduce(0, +)
        let protein = entries.map(\.proteinGrams).reduce(0, +)
        return (cal, protein)
    }

    /// Write today's food tracker totals into the daily log (Overview). Preserves steps and weight; overwrites calories and protein.
    func syncTodayFoodToOverview() {
        let todayKey = DailyLog.dateKey(from: Date())
        let (cal, protein) = foodTotals(for: todayKey)
        var log = dailyLogs[todayKey] ?? DailyLog(dateKey: todayKey, isManualOverride: false)
        log.caloriesConsumed = cal > 0 ? cal : nil
        log.proteinGrams = protein > 0 ? protein : nil
        log.isManualOverride = false
        dailyLogs[todayKey] = log
        save()
    }

    /// Key for a single suggested food item (messageId + index) so we don't add twice.
    func foodLogSuggestionKey(messageId: String, itemIndex: Int) -> String {
        "\(messageId)-\(itemIndex)"
    }

    func isFoodLogSuggestionApplied(messageId: String, itemIndex: Int) -> Bool {
        appliedFoodLogSuggestions.contains(foodLogSuggestionKey(messageId: messageId, itemIndex: itemIndex))
    }

    /// Add one suggested food item to today's food log and mark it as applied.
    func applyFoodLogSuggestion(messageId: String, itemIndex: Int, name: String, calories: Double, protein: Double, quantity: String) {
        let key = foodLogSuggestionKey(messageId: messageId, itemIndex: itemIndex)
        guard !appliedFoodLogSuggestions.contains(key) else { return }
        let todayKey = DailyLog.dateKey(from: Date())
        let displayName = quantity.isEmpty ? name : "\(name) (\(quantity))"
        let entry = FoodEntry(dateKey: todayKey, name: displayName, calories: calories, proteinGrams: protein)
        addFoodEntry(entry)
        appliedFoodLogSuggestions.insert(key)
        store.saveAppliedFoodLogSuggestions(Array(appliedFoodLogSuggestions))
    }

    private func load() {
        goals = store.loadGoals()
        hasCompletedOnboarding = store.loadOnboardingComplete()
        dailyLogs = store.loadDailyLogs()
        chatHistory = store.loadChatHistory()
        userChallenges = store.loadUserChallenges()
        foodEntries = store.loadFoodEntries()
        userAddedFoods = store.loadUserAddedFoods()
        appliedFoodLogSuggestions = Set(store.loadAppliedFoodLogSuggestions())
    }

    private func save() {
        if let g = goals { store.saveGoals(g) }
        store.saveOnboardingComplete(hasCompletedOnboarding)
        store.saveDailyLogs(dailyLogs)
        store.saveChatHistory(chatHistory)
        store.saveUserChallenges(userChallenges)
        store.saveFoodEntries(foodEntries)
        store.saveUserAddedFoods(userAddedFoods)
    }
}
