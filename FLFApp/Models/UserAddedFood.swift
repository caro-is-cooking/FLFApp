import Foundation

/// A food added by the user; persisted so it appears in search next time (and can be shared across users if we add sync later).
struct UserAddedFood: Codable, Identifiable, AddableFood {
    var id: String
    var name: String
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var gramsPerCup: Double?
    var gramsPerServing: Double?

    init(id: String = UUID().uuidString, name: String, caloriesPer100g: Double, proteinPer100g: Double, gramsPerCup: Double? = nil, gramsPerServing: Double? = nil) {
        self.id = id
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.gramsPerCup = gramsPerCup
        self.gramsPerServing = gramsPerServing
    }
}
