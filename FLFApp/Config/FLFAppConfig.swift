import Foundation

/// Chat is configured only here. End users never see settings or API keys.
///
/// **Ship the app:** Deploy the backend (see backend/README), set OPENAI_API_KEY there, then set `defaultBackendURL` below to your live backend URL. Done.
enum FLFAppConfig {

    /// Your deployed backend URL. Set this once; the app uses it for all chat and plate-photo analysis. No trailing slash.
    /// Example: "https://your-flf-backend.railway.app"
    static var defaultBackendURL: String? = "https://flfapp-production.up.railway.app"

    /// Only used for direct OpenAI when no backend is set (e.g. local dev). Prefer backend for production.
    static var defaultOpenAIAPIKey: String? {
        FLFAppConfigSecrets.openAIAPIKey
    }

    /// Optional extra instructions for the chatbot (direct OpenAI path only; backend has its own prompt).
    static var defaultChatbotContext: String? = nil
}
