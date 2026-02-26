import Foundation

final class DataStore {
    private let fileManager = FileManager.default
    private var docsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func path(_ name: String) -> URL {
        docsURL.appendingPathComponent(name)
    }
    
    func saveGoals(_ goals: UserGoals) {
        save(goals, to: "goals.json")
    }
    
    func loadGoals() -> UserGoals? {
        load(UserGoals.self, from: "goals.json")
    }
    
    func saveOnboardingComplete(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "flf_onboarding_complete")
    }
    
    func loadOnboardingComplete() -> Bool {
        UserDefaults.standard.bool(forKey: "flf_onboarding_complete")
    }
    
    func saveDailyLogs(_ logs: [String: DailyLog]) {
        let array = Array(logs.values)
        save(array, to: "daily_logs.json")
    }
    
    func loadDailyLogs() -> [String: DailyLog] {
        guard let array: [DailyLog] = load(from: "daily_logs.json") else { return [:] }
        return Dictionary(uniqueKeysWithValues: array.map { ($0.dateKey, $0) })
    }
    
    func saveChatHistory(_ messages: [ChatMessage]) {
        save(messages, to: "chat_history.json")
    }
    
    func loadChatHistory() -> [ChatMessage] {
        load(from: "chat_history.json") ?? []
    }
    
    func saveUserChallenges(_ challenges: [String]) {
        save(challenges, to: "user_challenges.json")
    }
    
    func loadUserChallenges() -> [String] {
        load(from: "user_challenges.json") ?? []
    }

    func saveFoodEntries(_ entries: [FoodEntry]) {
        save(entries, to: "food_entries.json")
    }

    func loadFoodEntries() -> [FoodEntry] {
        load(from: "food_entries.json") ?? []
    }

    func saveUserAddedFoods(_ foods: [UserAddedFood]) {
        save(foods, to: "user_added_foods.json")
    }

    func loadUserAddedFoods() -> [UserAddedFood] {
        load(from: "user_added_foods.json") ?? []
    }

    func saveAppliedFoodLogSuggestions(_ keys: [String]) {
        save(keys, to: "applied_food_log_suggestions.json")
    }

    func loadAppliedFoodLogSuggestions() -> [String] {
        load(from: "applied_food_log_suggestions.json") ?? []
    }

    func saveOpenAIAPIKey(_ key: String?) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed?.isEmpty == true ? nil : trimmed, forKey: "flf_openai_api_key")
    }
    
    func loadOpenAIAPIKey() -> String? {
        let s = UserDefaults.standard.string(forKey: "flf_openai_api_key")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let stored = (s?.isEmpty == true) ? nil : s
        let fallback = FLFAppConfig.defaultOpenAIAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fromConfig = (fallback?.isEmpty == true) ? nil : fallback
        return stored ?? fromConfig
    }
    
    /// Custom instructions for how the support chatbot should act (appended to system prompt).
    func saveChatbotContext(_ context: String?) {
        UserDefaults.standard.set(context, forKey: "flf_chatbot_context")
    }
    
    func loadChatbotContext() -> String? {
        let s = UserDefaults.standard.string(forKey: "flf_chatbot_context")
        let stored = s?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fromStored = (stored?.isEmpty == true) ? nil : stored
        let fromConfig = FLFAppConfig.defaultChatbotContext?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fromConfigNilIfEmpty = (fromConfig?.isEmpty == true) ? nil : fromConfig
        return fromStored ?? fromConfigNilIfEmpty
    }
    
    /// Backend base URL for chat (e.g. https://your-app.railway.app). When set, app uses backend so users don't need an API key.
    func saveChatBackendURL(_ url: String?) {
        let trimmed = url?.trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(trimmed?.isEmpty == true ? nil : trimmed, forKey: "flf_chat_backend_url")
    }
    
    func loadChatBackendURL() -> String? {
        let s = UserDefaults.standard.string(forKey: "flf_chat_backend_url")?.trimmingCharacters(in: .whitespaces)
        let stored = (s?.isEmpty == true) ? nil : s
        let fallback = FLFAppConfig.defaultBackendURL?.trimmingCharacters(in: .whitespaces)
        let fromConfig = (fallback?.isEmpty == true) ? nil : fallback
        return stored ?? fromConfig
    }
    
    private func save<T: Encodable>(_ value: T, to filename: String) {
        let url = path(filename)
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url)
        } catch {
            print("Save error \(filename): \(error)")
        }
    }
    
    private func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        load(from: filename) as T?
    }
    
    private func load<T: Decodable>(from filename: String) -> T? {
        let url = path(filename)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
