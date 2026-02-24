# FLF App – Diet & Exercise Tracker

iOS app to track diet and exercise, with a weekly calorie target (goal weight × 84), manual logging, and a support chatbot.

## Features

- **Home / onboarding**: Set your goal weight (lbs). Weekly calorie target = **goal weight × 84**.
- **Overview tab**: Time series of daily calories, protein, steps, and weight. Edit any day (calories, protein, steps, weight). See **weekly consumed vs target** and **calories left this week**.
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

- **Calories & protein (MyFitnessPal)**  
  MyFitnessPal does not offer a public API for third‑party apps. Options:
  1. **Manual entry**: Use the Overview tab and **Edit** on a day to type calories and protein (already implemented).
  2. **MyFitnessPal ↔ Apple Health**: If you use MFP’s Health app integration, you could read nutrition from HealthKit in the same way as steps (add HealthKit capability and a service that reads dietary energy and protein and updates `DailyLog`).
  3. **Future**: If MyFitnessPal or WHOOP add APIs or deeper Health integration, you can add sync in `Services/` and keep using the same Overview and data models.

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
      WeighInView.swift      # Daily weight log + progress chart (Week/Month/3M/All)
      SupportChatView.swift  # Chat UI, challenge menu, plate camera
      EditGoalView.swift     # Edit goal weight
    Models/
      UserGoals.swift
      DailyLog.swift
      ChatMessage.swift
      AppState.swift         # Global state
    Services/
      DataStore.swift        # Persistence (JSON in Documents)
      SupportChatService.swift  # Context + local/API responses
    Assets.xcassets/
```
