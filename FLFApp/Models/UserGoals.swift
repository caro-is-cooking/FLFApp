import Foundation

struct UserGoals: Codable, Equatable {
    var goalWeightLbs: Double
    var weeklyCalorieTarget: Double { goalWeightLbs * 84 }
    
    init(goalWeightLbs: Double) {
        self.goalWeightLbs = goalWeightLbs
    }
}
