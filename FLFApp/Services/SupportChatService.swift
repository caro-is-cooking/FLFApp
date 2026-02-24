import Foundation

// MARK: - System prompt template
enum SupportChatPrompt {
    static let baseInstructions = """
    You are a supportive, non-judgmental fat loss coach. Be warm, brief, and practical. \
    You have access to their goal weight, weekly calorie target, and things they find challenging. \
    Reference their data when relevant. If they ask you to remember something as a challenge, acknowledge it. \
    Do not give medical advice. Keep responses concise (a few short paragraphs max) unless they ask for more. \
    Ground your advice in the coaching framework below. \
    When the user shares a photo of their plate or meal, estimate the calories and give brief, supportive feedback (e.g. balance, volume-eating tips, how it fits their budget).
    """
    
    /// Core coaching framework (from fat loss coach). Use this to guide your tone and advice.
    static let coachFramework = """
    COACHING FRAMEWORK — Use these concepts when supporting the user:

    **Your WHY:** Weight loss isn’t one-size-fits-all. The first step is understanding WHY they want to lose weight—e.g. setting an example for kids, feeling confident with a partner, less stress about clothes. Encourage them to name and use their why as a daily reminder, especially when it’s hard.

    **Future self:** Their future self is them. Encourage envisioning the lighter (physically and mentally) version: how she feels around food (confident, at ease, calm, energized), how she looks in the mirror, how she feels getting out of bed. A day in the life of their ideal self (wake, exercise, meals, wind-down) helps clarify what to be consistent with and what to let go.

    **Food budget:** They have a weekly calorie budget. Like a spending budget: if they overspend one day, they can balance it by staying under other days. The goal is to be consistently under budget for the week. All foods and drinks count as energy (calories).

    **Volume eating:** Eat more for less—not to “trick” the body but to feel nourished and full while staying in budget. Protein and fiber are key. You should hit your body weight in grams of protein every day because protein is what keeps you full. Examples: It's better to have a double serving of greek yogurt than a single serving of greek yogurt + granola; double the protein in salads; veggies to munch while cooking. Snack once a day or not at all; make snacks meaningful (real hunger or a small intentional dessert).

    **Dining out:** Check the menu online and decide before arriving. Order salad first (dressing on the side—two tbsp can add 150–200 cal) or broth-based soup. Look for lower-calorie words: steamed, baked, roasted, grilled, broiled, seared. Avoid higher-calorie words: creamy, buttery, breaded, fried, battered, glazed, alfredo. Request butter/sauces on the side; use the fork-dip method for dressings. Ask for a to-go box and put half away immediately. Say no to bread basket/chips or take one portion. Drink water; don’t arrive starving; plan a short walk after. Pop a mint when done. Give yourself a quick pep talk. For restricted diets: plan ahead, ask for off-menu options, pile on sides, choose variety (grains, plant protein, veggies).

    **Hunger vs. cravings:** Physical hunger = biologically driven, emptiness, low energy, irritability; it’s normal to feel a bit hungry in a deficit. Manage it with regular meals, protein and fiber, starting with salad or soup. Cravings = intense urge for a specific food, often triggered by sight/smell, stress, boredom, social media, places. Address the trigger: rest if tired, activity or support if bored, redirect thoughts, drink water (64+ oz daily), go for a walk. Learn to address the trigger, not the craving.
    """
}

// MARK: - OpenAI API types
private struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int?
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIChatResponse: Decodable {
    let choices: [Choice]?
    let error: OpenAIError?
    
    struct Choice: Decodable {
        let message: OpenAIMessage
    }
    
    struct OpenAIError: Decodable {
        let message: String?
    }
}

// MARK: - Service
final class SupportChatService {
    private let store = DataStore()
    private let maxHistoryMessages = 20
    private let model = "gpt-4o-mini"
    /// Fail fast instead of hanging; user gets a clear error and can retry.
    private let requestTimeout: TimeInterval = 25
    
    var apiKey: String? {
        store.loadOpenAIAPIKey()
    }
    
    func setAPIKey(_ key: String?) {
        store.saveOpenAIAPIKey(key)
    }
    
    /// Backend URL is set only in code (FLFAppConfig.defaultBackendURL). Users never configure this.
    private var backendBaseURL: String? {
        let url = FLFAppConfig.defaultBackendURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (url?.isEmpty == true) ? nil : url
    }
    
    func buildSystemPrompt(appState: AppState) -> String {
        var parts: [String] = []
        parts.append(SupportChatPrompt.baseInstructions)
        parts.append(SupportChatPrompt.coachFramework)
        if appState.goalWeightLbs > 0 {
            parts.append("User's goal weight: \(appState.goalWeightLbs) lbs. Weekly calorie target: \(Int(appState.weeklyCalorieTarget)) cal (this is their weekly food budget).")
        }
        if !appState.userChallenges.isEmpty {
            parts.append("Things the user finds challenging: \(appState.userChallenges.joined(separator: "; ")).")
        }
        let custom = store.loadChatbotContext() ?? ""
        if !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Additional instructions for how you should act:\n\(custom)")
        }
        return parts.joined(separator: "\n\n")
    }
    
    func respond(to userMessage: String, appState: AppState, imageBase64: String? = nil) async -> String {
        if let base = backendBaseURL, !base.isEmpty, let url = URL(string: base.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat") {
            return await callBackend(url: url, userMessage: userMessage, appState: appState, imageBase64: imageBase64)
        }
        if imageBase64 != nil {
            return "I can't analyze photos right now. Please try again later or type your question."
        }
        if let key = apiKey, !key.isEmpty {
            let systemPrompt = buildSystemPrompt(appState: appState)
            return await callOpenAI(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: appState.chatHistory,
                apiKey: key
            )
        }
        return localFallback(userMessage: userMessage)
    }
    
    private struct BackendChatRequest: Encodable {
        let messages: [BackendMessage]
        let imageBase64: String?
        let userContext: UserContext?
    }
    
    private struct UserContext: Encodable {
        let goalWeightLbs: Double
        let weeklyCalorieTarget: Double
        let userChallenges: [String]
    }
    
    private struct BackendMessage: Encodable {
        let role: String
        let content: String
    }
    
    private struct BackendChatResponse: Decodable {
        let reply: String?
        let error: String?
    }
    
    private func callBackend(url: URL, userMessage: String, appState: AppState, imageBase64: String? = nil) async -> String {
        let recent = Array(appState.chatHistory.suffix(maxHistoryMessages))
        var messages: [BackendMessage] = recent.map { msg in
            BackendMessage(role: msg.role == .user ? "user" : "assistant", content: msg.content)
        }
        messages.append(BackendMessage(role: "user", content: userMessage))
        
        let userContext = UserContext(
            goalWeightLbs: appState.goalWeightLbs,
            weeklyCalorieTarget: appState.weeklyCalorieTarget,
            userChallenges: appState.userChallenges
        )
        let body = BackendChatRequest(messages: messages, imageBase64: imageBase64, userContext: userContext)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            return "Something went wrong. Please try again."
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.timeoutInterval = requestTimeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return "Something went wrong. Please try again."
            }
            let decoded = try? JSONDecoder().decode(BackendChatResponse.self, from: data)
            if http.statusCode == 200 {
                if let reply = decoded?.reply, !reply.isEmpty {
                    return reply.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return decoded?.error ?? "Something went wrong. Please try again."
            }
            return "Something went wrong. Please try again."
        } catch let err as URLError where err.code == .timedOut {
            return "This is taking longer than usual. Please try again."
        } catch {
            return "We're having trouble connecting. Please try again."
        }
    }
    
    private func callOpenAI(systemPrompt: String, userMessage: String, history: [ChatMessage], apiKey: String) async -> String {
        var messages: [OpenAIMessage] = [
            OpenAIMessage(role: "system", content: systemPrompt)
        ]
        let recent = Array(history.suffix(maxHistoryMessages))
        for msg in recent {
            let role = msg.role == .user ? "user" : "assistant"
            messages.append(OpenAIMessage(role: role, content: msg.content))
        }
        messages.append(OpenAIMessage(role: "user", content: userMessage))
        
        let body = OpenAIChatRequest(model: model, messages: messages, max_tokens: 512)
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
              let bodyData = try? JSONEncoder().encode(body) else {
            return "Something went wrong building the request."
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.timeoutInterval = requestTimeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return "Invalid response from server."
            }
            if http.statusCode != 200 {
                if let err = try? JSONDecoder().decode(OpenAIChatResponse.self, from: data), let apiErr = err.error {
                    return "API error: \(apiErr.message ?? "Unknown"). Check your API key and try again."
                }
                return "Request failed (status \(http.statusCode)). Check your API key."
            }
            let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            if let text = decoded.choices?.first?.message.content, !text.isEmpty {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return "No response from the model."
        } catch let err as URLError where err.code == .timedOut {
            return "Request timed out. Check your connection and API key, then try again."
        } catch {
            return "Network error: \(error.localizedDescription). Check your connection and API key."
        }
    }
    
    private func localFallback(userMessage: String) -> String {
        let lower = userMessage.lowercased()
        if lower.contains("challeng") || lower.contains("hard") || lower.contains("struggle") {
            return "It sounds like you're hitting a rough patch—that's really common. Would you like me to remember this so I can check in later? You can also add it to your challenges in this chat so I keep it in mind. What would help most right now: a small step for today or just acknowledging that it's okay to have off days?"
        }
        if lower.contains("calor") || lower.contains("budget") || lower.contains("week") {
            return "Your weekly target is in your Overview tab—you can see how many calories you have left for the week there. If you're under, you have room; if you're over, we can focus on the next week without guilt. Want to talk through a plan for the rest of the week?"
        }
        if lower.contains("weight") || lower.contains("scale") {
            return "Daily weigh-ins are just data—they help you see trends, not define you. Keep logging in the Weigh In tab; over time the trend matters more than any single number. How are you feeling aside from the number?"
        }
        if lower.contains("goal") {
            return "I've got your goal weight and weekly calorie target in mind. Consistency beats perfection: small, sustainable steps will get you there. What's one thing you can do today that feels doable?"
        }
        return "I'm here to support you. Tell me about your wins, struggles, or questions—I'll do my best to help."
    }
}
