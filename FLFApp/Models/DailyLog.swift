import Foundation

struct DailyLog: Codable, Identifiable {
    var id: String { dateKey }
    var dateKey: String  // yyyy-MM-dd
    var caloriesConsumed: Double?
    var proteinGrams: Double?
    var stepCount: Int?
    var weightLbs: Double?
    var isManualOverride: Bool  // true if user edited vs synced from app
    
    init(dateKey: String, caloriesConsumed: Double? = nil, proteinGrams: Double? = nil, stepCount: Int? = nil, weightLbs: Double? = nil, isManualOverride: Bool = false) {
        self.dateKey = dateKey
        self.caloriesConsumed = caloriesConsumed
        self.proteinGrams = proteinGrams
        self.stepCount = stepCount
        self.weightLbs = weightLbs
        self.isManualOverride = isManualOverride
    }
    
    static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }
    
    static func dateKey(from date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
