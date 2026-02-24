import Foundation

struct ChatMessage: Codable, Identifiable {
    var id: UUID
    var role: Role
    var content: String
    var timestamp: Date
    
    enum Role: String, Codable {
        case user
        case assistant
    }
    
    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
