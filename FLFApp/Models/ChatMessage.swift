import Foundation

struct ChatMessage: Codable, Identifiable {
    var id: UUID
    var role: Role
    var content: String
    var timestamp: Date
    /// Relative path (e.g. "ChatImages/<id>.jpg") for user message image attachment; nil if none.
    var attachmentImagePath: String?
    
    enum Role: String, Codable {
        case user
        case assistant
    }
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, attachmentImagePath
    }
    
    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), attachmentImagePath: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.attachmentImagePath = attachmentImagePath
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        role = try c.decode(Role.self, forKey: .role)
        content = try c.decode(String.self, forKey: .content)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        attachmentImagePath = try c.decodeIfPresent(String.self, forKey: .attachmentImagePath)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(role, forKey: .role)
        try c.encode(content, forKey: .content)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encodeIfPresent(attachmentImagePath, forKey: .attachmentImagePath)
    }
}
