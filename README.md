# FLF App – Diet & Exercise Tracker

iOS app to track diet and exercise, with a weekly calorie target (goal weight × 84), manual logging, and a support chatbot.

## Features

- **Home / onboarding**: Set your goal weight (lbs). Weekly calorie target = **goal weight × 84**.
- **Overview tab**: Time series of daily calories, protein, steps, and weight. Edit any day (calories, protein, steps, weight). See **weekly consumed vs target** and **calories left this week**.
- **Food tab**: Log what you eat with a built-in list of common foods (calories and protein per serving) or add custom entries. See today’s running total; tap **Sync to Overview** to push the day’s totals into the Overview so they count toward your weekly budget.
- **Weigh In tab**: Log your morning weight; view **progress over time** with a line chart. Use the **Week / Month / 3 Months / All** selector to zoom the chart. Recent weigh-ins list below.
- **Support Chat tab**: Chatbot that uses your goal and weekly target, remembers challenges you add, and supports your fat loss journey. **Plate camera:** tap the camera icon to take or choose a photo of your plate; the bot estimates calories and gives feedback. All configuration is in code (see below); end users never see settings or API keys.

## Opening the project

1. Open **Xcode**.
2. **File → Open** and select the `FLFApp` folder (the one containing `FLFApp.xcodeproj`).
3. Select the **FLFApp** scheme and a simulator or device, then **Run** (⌘R).

## Integrations (WHOOP, MyFitnessPal)

- **Steps (WHOOP)**  
  WHOOP syncs to **Apple Health**. To use that data in the app:
  1. In Xcode, select the **FLFApp** target → **Signing & Capabilities** → **+ Capability** → add **HealthKit**.
  2. Enable **HealthKit** and the **Background Delivery** option if you want background updates.
  3. Add a **HealthKit** service in the app that reads step count (e.g. `HKQuantityType.quantityType(forIdentifier: .stepCount)`) and writes into the app’s daily logs. The existing **Overview** and **LogEditorView** already support displaying and overwriting steps; you’d be populating/updating `DailyLog.stepCount` from Health.

- **Calories & protein**  
  The app includes a **Food** tab with a built-in list of ~90 common foods (calories and protein per serving); you can also add custom entries. Use **Sync to Overview** to send the day’s totals to the Overview. For external data:
  1. **Manual entry**: Use the Overview tab and **Edit** on a day to type calories and protein (already implemented).
  2. **MyFitnessPal / Apple Health**: MyFitnessPal has no public API. If you use MFP’s Health integration, you could add a HealthKit service to read dietary energy and protein and update `DailyLog`. Same pattern as steps.
  3. **Public food APIs** (optional): [USDA FoodData Central](https://fdc.nal.usda.gov/) and [Nutritionix](https://developer.nutritionix.com/) offer free API keys for larger food databases; you could add search against one of them in the Food tab and cache results locally.

## Changing your goal weight

In the **Overview** tab, tap **Edit goal** in the toolbar to change your goal weight. The formula **weekly calories = goal weight × 84** is in `UserGoals.weeklyCalorieTarget`.

## Support chat (developer setup only)

Everything is hardcoded so end users have a seamless experience—no settings or API keys in the app.

1. **Deploy the backend** (see `backend/README.md`). Set `OPENAI_API_KEY` in the backend environment (e.g. Railway, Render). The backend owns the system prompt and plate-photo analysis.
2. **Set the backend URL once** in **`FLFApp/Config/FLFAppConfig.swift`**: assign your live URL to `defaultBackendURL` (e.g. `"https://your-flf-backend.railway.app"`). The app uses this for all chat and photo analysis.
3. **Optional (local dev only):** To test without the backend, set `openAIAPIKey` in `FLFAppConfig.Secrets.swift`. For production, use the backend only.

If neither backend URL nor API key is set, the app shows friendly built-in replies.

## Backend (optional)

See **`backend/README.md`** for how to run and deploy the chat backend so all app users can use the support chat without an API key. The backend holds the OpenAI key and proxies requests from the app.

## Requirements

- Xcode 14+
- iOS 16+
- Swift 5

## Project structure

```
FLFApp/
  FLFApp.xcodeproj/
  backend/                    # Optional: Node server so users don't need an API key
    package.json
    server.js
    README.md
  FLFApp/
    FLFAppApp.swift          # App entry, onboarding vs main tabs
    Config/
      FLFAppConfig.swift           # defaultBackendURL, defaultChatbotContext
      FLFAppConfig.Secrets.swift   # openAIAPIKey (edit here; keep out of git)
    Views/
      HomeView.swift         # Goal weight entry, weekly target
      MainTabView.swift      # Tab bar: Overview, Weigh In, Support
      OverviewView.swift     # Time series, weekly summary, edit day
      LogEditorView.swift    # Edit calories, protein, steps, weight for a day
      FoodTrackerView.swift  # Food log for the day, sync to Overview
      AddFoodView.swift      # Add from common foods or custom entry
      WeighInView.swift      # Daily weight log + progress chart (Week/Month/3M/All)
      SupportChatView.swift  # Chat UI, challenge menu, plate camera
      EditGoalView.swift     # Edit goal weight
    Models/
      UserGoals.swift
      DailyLog.swift
      ChatMessage.swift
      AppState.swift         # Global state
      FoodEntry.swift        # One food log entry
      CommonFoods.swift     # Built-in food list (calories, protein)
    Services/
      DataStore.swift        # Persistence (JSON in Documents)
      SupportChatService.swift  # Context + local/API responses
    Assets.xcassets/
```
