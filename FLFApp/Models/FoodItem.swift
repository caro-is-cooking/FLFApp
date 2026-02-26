import Foundation

/// Unit for amount when adding a food. Ounces are converted to grams (1 oz ≈ 28.35 g).
enum FoodAmountUnit: String, CaseIterable, Identifiable {
    case grams = "g"
    case ounces = "oz"
    case cup = "cup"
    case serving = "serving"
    var id: String { rawValue }
}

/// Protocol for any food that can be added with a chosen amount (common or user-added).
/// All nutrition is stored per 100g so we can compute for any gram amount.
protocol AddableFood: Identifiable {
    var id: String { get }
    var name: String { get }
    var caloriesPer100g: Double { get }
    var proteinPer100g: Double { get }
    /// Grams per 1 cup (if nil, cup option is hidden).
    var gramsPerCup: Double? { get }
    /// Grams per 1 "serving" (if nil, serving option is hidden).
    var gramsPerServing: Double? { get }
}

extension AddableFood {
    func calories(forGrams grams: Double) -> Double {
        (grams / 100) * caloriesPer100g
    }
    func protein(forGrams grams: Double) -> Double {
        (grams / 100) * proteinPer100g
    }
    func grams(from amount: Double, unit: FoodAmountUnit) -> Double? {
        switch unit {
        case .grams: return amount
        case .ounces: return amount * 28.35
        case .cup: return gramsPerCup.map { amount * $0 }
        case .serving: return gramsPerServing.map { amount * $0 }
        }
    }
    var canUseCup: Bool { gramsPerCup != nil }
    var canUseServing: Bool { gramsPerServing != nil }
}

/// Type-erased addable food so we can show common + user foods in one list and pass to the amount picker.
enum SearchableFoodItem: AddableFood {
    case common(CommonFood)
    case user(UserAddedFood)

    var id: String {
        switch self {
        case .common(let f): return "c-\(f.id)"
        case .user(let f): return "u-\(f.id)"
        }
    }
    var name: String {
        switch self {
        case .common(let f): return f.name
        case .user(let f): return f.name
        }
    }
    var caloriesPer100g: Double {
        switch self {
        case .common(let f): return f.caloriesPer100g
        case .user(let f): return f.caloriesPer100g
        }
    }
    var proteinPer100g: Double {
        switch self {
        case .common(let f): return f.proteinPer100g
        case .user(let f): return f.proteinPer100g
        }
    }
    var gramsPerCup: Double? {
        switch self {
        case .common(let f): return f.gramsPerCup
        case .user(let f): return f.gramsPerCup
        }
    }
    var gramsPerServing: Double? {
        switch self {
        case .common(let f): return f.gramsPerServing
        case .user(let f): return f.gramsPerServing
        }
    }
}
