import Foundation

/// A single food log entry (one item logged for a day).
struct FoodEntry: Codable, Identifiable {
    var id: String
    var dateKey: String
    var name: String
    var calories: Double
    var proteinGrams: Double

    init(id: String = UUID().uuidString, dateKey: String, name: String, calories: Double, proteinGrams: Double) {
        self.id = id
        self.dateKey = dateKey
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
    }
}
