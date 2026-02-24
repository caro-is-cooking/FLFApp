import Foundation

/// Local-only: set your OpenAI API key here for dev when not using the backend.
/// To avoid committing your key: run in terminal from repo root:
///   git update-index --assume-unchanged FLFApp/FLFApp/Config/FLFAppConfig.Secrets.swift
enum FLFAppConfigSecrets {
    static let openAIAPIKey: String? = nil
}
