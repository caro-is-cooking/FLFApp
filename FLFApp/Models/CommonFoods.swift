import Foundation

/// One item in the built-in food database. Nutrition per 100g so users can add by gram, ounce, or cup.
struct CommonFood: Identifiable, AddableFood {
    let id: String
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let gramsPerCup: Double?
    let gramsPerServing: Double?

    init(id: String, name: String, caloriesPer100g: Double, proteinPer100g: Double, gramsPerCup: Double? = nil, gramsPerServing: Double? = nil) {
        self.id = id
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.gramsPerCup = gramsPerCup
        self.gramsPerServing = gramsPerServing
    }
}

/// Built-in list of common foods + Chipotle/fast-food ingredients. Nutrition per 100g; optional cup/serving sizes.
enum CommonFoods {
    static let all: [CommonFood] = [
        // —— Proteins (per 100g) ——
        CommonFood(id: "chicken-breast", name: "Chicken breast, grilled", caloriesPer100g: 165, proteinPer100g: 31, gramsPerCup: 140, gramsPerServing: 113),
        CommonFood(id: "chicken-thigh", name: "Chicken thigh, skinless", caloriesPer100g: 185, proteinPer100g: 25, gramsPerServing: 113),
        CommonFood(id: "ground-turkey", name: "Ground turkey (93% lean)", caloriesPer100g: 150, proteinPer100g: 19, gramsPerServing: 113),
        CommonFood(id: "ground-beef", name: "Ground beef (85% lean)", caloriesPer100g: 190, proteinPer100g: 21, gramsPerServing: 113),
        CommonFood(id: "salmon", name: "Salmon, baked", caloriesPer100g: 207, proteinPer100g: 22, gramsPerServing: 113),
        CommonFood(id: "tilapia", name: "Tilapia, baked", caloriesPer100g: 96, proteinPer100g: 20, gramsPerServing: 113),
        CommonFood(id: "shrimp", name: "Shrimp", caloriesPer100g: 99, proteinPer100g: 21, gramsPerServing: 113),
        CommonFood(id: "eggs", name: "Eggs, whole", caloriesPer100g: 155, proteinPer100g: 13, gramsPerServing: 100),
        CommonFood(id: "egg-whites", name: "Egg whites", caloriesPer100g: 52, proteinPer100g: 11, gramsPerCup: 240),
        CommonFood(id: "greek-yogurt", name: "Greek yogurt, plain nonfat", caloriesPer100g: 59, proteinPer100g: 10, gramsPerCup: 245),
        CommonFood(id: "cottage-cheese", name: "Cottage cheese, 2%", caloriesPer100g: 81, proteinPer100g: 10, gramsPerCup: 226),
        CommonFood(id: "tofu", name: "Tofu, firm", caloriesPer100g: 78, proteinPer100g: 9, gramsPerServing: 113),
        CommonFood(id: "tuna-canned", name: "Tuna, canned in water", caloriesPer100g: 88, proteinPer100g: 19, gramsPerServing: 85),
        CommonFood(id: "pork-chop", name: "Pork chop, lean", caloriesPer100g: 171, proteinPer100g: 23, gramsPerServing: 113),
        CommonFood(id: "bacon", name: "Bacon", caloriesPer100g: 541, proteinPer100g: 37, gramsPerServing: 28),
        CommonFood(id: "whey-powder", name: "Whey protein powder", caloriesPer100g: 400, proteinPer100g: 80, gramsPerServing: 30),
        // —— Dairy ——
        CommonFood(id: "milk-whole", name: "Milk, whole", caloriesPer100g: 61, proteinPer100g: 3.2, gramsPerCup: 244),
        CommonFood(id: "milk-2", name: "Milk, 2%", caloriesPer100g: 50, proteinPer100g: 3.3, gramsPerCup: 244),
        CommonFood(id: "milk-skim", name: "Milk, skim", caloriesPer100g: 34, proteinPer100g: 3.4, gramsPerCup: 245),
        CommonFood(id: "almond-milk", name: "Almond milk, unsweetened", caloriesPer100g: 13, proteinPer100g: 0.4, gramsPerCup: 240),
        CommonFood(id: "cheddar", name: "Cheddar cheese", caloriesPer100g: 402, proteinPer100g: 25, gramsPerServing: 28),
        CommonFood(id: "mozzarella", name: "Mozzarella, part-skim", caloriesPer100g: 254, proteinPer100g: 24, gramsPerServing: 28),
        CommonFood(id: "cream-cheese", name: "Cream cheese", caloriesPer100g: 342, proteinPer100g: 5.9, gramsPerServing: 28),
        // —— Grains & carbs ——
        CommonFood(id: "rice-white", name: "White rice, cooked", caloriesPer100g: 130, proteinPer100g: 2.7, gramsPerCup: 195),
        CommonFood(id: "rice-brown", name: "Brown rice, cooked", caloriesPer100g: 112, proteinPer100g: 2.6, gramsPerCup: 195),
        CommonFood(id: "quinoa", name: "Quinoa, cooked", caloriesPer100g: 120, proteinPer100g: 4.4, gramsPerCup: 185),
        CommonFood(id: "oatmeal", name: "Oatmeal, cooked", caloriesPer100g: 68, proteinPer100g: 2.4, gramsPerCup: 234),
        CommonFood(id: "bread-whole", name: "Whole wheat bread", caloriesPer100g: 247, proteinPer100g: 13.4, gramsPerServing: 28),
        CommonFood(id: "bread-white", name: "White bread", caloriesPer100g: 265, proteinPer100g: 9, gramsPerServing: 28),
        CommonFood(id: "pasta", name: "Pasta, cooked", caloriesPer100g: 131, proteinPer100g: 5, gramsPerCup: 140),
        CommonFood(id: "sweet-potato", name: "Sweet potato, baked", caloriesPer100g: 90, proteinPer100g: 2, gramsPerServing: 130),
        CommonFood(id: "potato", name: "Potato, baked", caloriesPer100g: 93, proteinPer100g: 2.5, gramsPerServing: 173),
        CommonFood(id: "bagel", name: "Bagel, plain", caloriesPer100g: 257, proteinPer100g: 10, gramsPerServing: 100),
        CommonFood(id: "tortilla", name: "Tortilla, flour", caloriesPer100g: 304, proteinPer100g: 8.5, gramsPerServing: 49),
        CommonFood(id: "cereal-cheerios", name: "Cereal, Cheerios", caloriesPer100g: 376, proteinPer100g: 12.1, gramsPerCup: 30),
        CommonFood(id: "granola", name: "Granola", caloriesPer100g: 489, proteinPer100g: 10, gramsPerCup: 120),
        // —— Vegetables ——
        CommonFood(id: "broccoli", name: "Broccoli, steamed", caloriesPer100g: 35, proteinPer100g: 2.4, gramsPerCup: 91),
        CommonFood(id: "spinach", name: "Spinach, raw", caloriesPer100g: 23, proteinPer100g: 2.9, gramsPerCup: 30),
        CommonFood(id: "kale", name: "Kale, raw", caloriesPer100g: 35, proteinPer100g: 2.9, gramsPerCup: 67),
        CommonFood(id: "green-beans", name: "Green beans", caloriesPer100g: 31, proteinPer100g: 1.8, gramsPerCup: 125),
        CommonFood(id: "carrots", name: "Carrots, raw", caloriesPer100g: 41, proteinPer100g: 0.9, gramsPerServing: 61),
        CommonFood(id: "avocado", name: "Avocado", caloriesPer100g: 160, proteinPer100g: 2, gramsPerServing: 100),
        CommonFood(id: "tomato", name: "Tomato", caloriesPer100g: 18, proteinPer100g: 0.9, gramsPerServing: 123),
        CommonFood(id: "cucumber", name: "Cucumber", caloriesPer100g: 15, proteinPer100g: 0.7, gramsPerServing: 52),
        CommonFood(id: "bell-pepper", name: "Bell pepper", caloriesPer100g: 31, proteinPer100g: 1, gramsPerServing: 74),
        CommonFood(id: "zucchini", name: "Zucchini", caloriesPer100g: 17, proteinPer100g: 1.2, gramsPerCup: 124),
        CommonFood(id: "cauliflower", name: "Cauliflower", caloriesPer100g: 25, proteinPer100g: 1.9, gramsPerCup: 100),
        CommonFood(id: "brussels", name: "Brussels sprouts", caloriesPer100g: 43, proteinPer100g: 3.4, gramsPerCup: 88),
        CommonFood(id: "corn", name: "Corn", caloriesPer100g: 86, proteinPer100g: 3.3, gramsPerCup: 164),
        CommonFood(id: "peas", name: "Peas, cooked", caloriesPer100g: 84, proteinPer100g: 5.4, gramsPerCup: 160),
        CommonFood(id: "black-beans", name: "Black beans, cooked", caloriesPer100g: 132, proteinPer100g: 8.9, gramsPerCup: 172),
        CommonFood(id: "lentils", name: "Lentils, cooked", caloriesPer100g: 116, proteinPer100g: 9, gramsPerCup: 198),
        // —— Fruits ——
        CommonFood(id: "apple", name: "Apple", caloriesPer100g: 52, proteinPer100g: 0.3, gramsPerServing: 182),
        CommonFood(id: "banana", name: "Banana", caloriesPer100g: 89, proteinPer100g: 1.1, gramsPerServing: 118),
        CommonFood(id: "orange", name: "Orange", caloriesPer100g: 47, proteinPer100g: 0.9, gramsPerServing: 131),
        CommonFood(id: "strawberries", name: "Strawberries", caloriesPer100g: 32, proteinPer100g: 0.7, gramsPerCup: 152),
        CommonFood(id: "blueberries", name: "Blueberries", caloriesPer100g: 57, proteinPer100g: 0.7, gramsPerCup: 148),
        CommonFood(id: "grapes", name: "Grapes", caloriesPer100g: 69, proteinPer100g: 0.7, gramsPerCup: 151),
        CommonFood(id: "watermelon", name: "Watermelon", caloriesPer100g: 30, proteinPer100g: 0.6, gramsPerCup: 152),
        CommonFood(id: "mango", name: "Mango", caloriesPer100g: 60, proteinPer100g: 0.8, gramsPerCup: 165),
        CommonFood(id: "peach", name: "Peach", caloriesPer100g: 39, proteinPer100g: 0.9, gramsPerServing: 150),
        CommonFood(id: "raspberries", name: "Raspberries", caloriesPer100g: 52, proteinPer100g: 1.2, gramsPerCup: 123),
        // —— Nuts & seeds ——
        CommonFood(id: "almonds", name: "Almonds", caloriesPer100g: 579, proteinPer100g: 21, gramsPerServing: 28),
        CommonFood(id: "peanut-butter", name: "Peanut butter", caloriesPer100g: 588, proteinPer100g: 25, gramsPerServing: 32),
        CommonFood(id: "cashews", name: "Cashews", caloriesPer100g: 553, proteinPer100g: 18, gramsPerServing: 28),
        CommonFood(id: "walnuts", name: "Walnuts", caloriesPer100g: 654, proteinPer100g: 15, gramsPerServing: 28),
        CommonFood(id: "chia", name: "Chia seeds", caloriesPer100g: 486, proteinPer100g: 17, gramsPerServing: 12),
        // —— Common meals & snacks ——
        CommonFood(id: "protein-bar", name: "Protein bar", caloriesPer100g: 400, proteinPer100g: 40, gramsPerServing: 60),
        CommonFood(id: "hummus", name: "Hummus", caloriesPer100g: 166, proteinPer100g: 7.9, gramsPerServing: 60),
        CommonFood(id: "latte", name: "Latte", caloriesPer100g: 50, proteinPer100g: 2.8, gramsPerServing: 360),
        CommonFood(id: "soda", name: "Soda", caloriesPer100g: 42, proteinPer100g: 0, gramsPerServing: 355),
        CommonFood(id: "oj", name: "Orange juice", caloriesPer100g: 45, proteinPer100g: 0.7, gramsPerCup: 248),
        CommonFood(id: "chips", name: "Chips", caloriesPer100g: 536, proteinPer100g: 7, gramsPerServing: 28),
        CommonFood(id: "dark-chocolate", name: "Dark chocolate", caloriesPer100g: 546, proteinPer100g: 4.9, gramsPerServing: 28),
        CommonFood(id: "pizza-slice", name: "Pizza slice, cheese", caloriesPer100g: 266, proteinPer100g: 11, gramsPerServing: 107),
        CommonFood(id: "turkey-deli", name: "Turkey breast, deli", caloriesPer100g: 105, proteinPer100g: 16, gramsPerServing: 85),

        // —— Chipotle (per serving ≈ 4 oz / 113g where applicable; nutrition from Chipotle) ——
        CommonFood(id: "chipotle-chicken", name: "Chipotle – Chicken", caloriesPer100g: 159, proteinPer100g: 28, gramsPerServing: 113),
        CommonFood(id: "chipotle-steak", name: "Chipotle – Steak", caloriesPer100g: 168, proteinPer100g: 26, gramsPerServing: 113),
        CommonFood(id: "chipotle-carnitas", name: "Chipotle – Carnitas", caloriesPer100g: 195, proteinPer100g: 22, gramsPerServing: 113),
        CommonFood(id: "chipotle-barbacoa", name: "Chipotle – Barbacoa", caloriesPer100g: 170, proteinPer100g: 25, gramsPerServing: 113),
        CommonFood(id: "chipotle-sofritas", name: "Chipotle – Sofritas", caloriesPer100g: 150, proteinPer100g: 12, gramsPerServing: 113),
        CommonFood(id: "chipotle-white-rice", name: "Chipotle – White rice", caloriesPer100g: 186, proteinPer100g: 3.5, gramsPerServing: 113),
        CommonFood(id: "chipotle-brown-rice", name: "Chipotle – Brown rice", caloriesPer100g: 186, proteinPer100g: 3.5, gramsPerServing: 113),
        CommonFood(id: "chipotle-black-beans", name: "Chipotle – Black beans", caloriesPer100g: 115, proteinPer100g: 7, gramsPerServing: 113),
        CommonFood(id: "chipotle-pinto-beans", name: "Chipotle – Pinto beans", caloriesPer100g: 115, proteinPer100g: 7, gramsPerServing: 113),
        CommonFood(id: "chipotle-fajita-veg", name: "Chipotle – Fajita veggies", caloriesPer100g: 27, proteinPer100g: 1.2, gramsPerServing: 113),
        CommonFood(id: "chipotle-fresh-salsa", name: "Chipotle – Fresh tomato salsa", caloriesPer100g: 22, proteinPer100g: 0, gramsPerServing: 113),
        CommonFood(id: "chipotle-green-salsa", name: "Chipotle – Tomatillo green-chili salsa", caloriesPer100g: 27, proteinPer100g: 0, gramsPerServing: 57),
        CommonFood(id: "chipotle-red-salsa", name: "Chipotle – Tomatillo red-chili salsa", caloriesPer100g: 53, proteinPer100g: 0, gramsPerServing: 57),
        CommonFood(id: "chipotle-corn-salsa", name: "Chipotle – Roasted chili-corn salsa", caloriesPer100g: 71, proteinPer100g: 2.7, gramsPerServing: 113),
        CommonFood(id: "chipotle-sour-cream", name: "Chipotle – Sour cream", caloriesPer100g: 193, proteinPer100g: 2.8, gramsPerServing: 57),
        CommonFood(id: "chipotle-cheese", name: "Chipotle – Cheese", caloriesPer100g: 393, proteinPer100g: 25, gramsPerServing: 28),
        CommonFood(id: "chipotle-guac", name: "Chipotle – Guacamole", caloriesPer100g: 167, proteinPer100g: 2, gramsPerServing: 113),
        CommonFood(id: "chipotle-lettuce", name: "Chipotle – Lettuce", caloriesPer100g: 15, proteinPer100g: 1.4, gramsPerServing: 28),
        CommonFood(id: "chipotle-tortilla-flour", name: "Chipotle – Flour tortilla", caloriesPer100g: 317, proteinPer100g: 8.8, gramsPerServing: 85),
        CommonFood(id: "chipotle-tortilla-corn", name: "Chipotle – Corn tortilla", caloriesPer100g: 218, proteinPer100g: 5.8, gramsPerServing: 42),
    ]

    static func search(_ query: String) -> [CommonFood] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return all }
        return all.filter { $0.name.lowercased().contains(q) }
    }
}
