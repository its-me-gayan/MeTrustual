# MeTrustual 🌸

**Your cycle, your story.**

MeTrustual is a production-ready Flutter menstrual cycle tracker designed for girls and women worldwide (ages 12+). It features a beautiful, soft pink/rose theme, private-first data handling, and accurate cycle predictions.

## 🚀 Features

- **Pixel-Perfect UI**: Replicated exactly from the provided design specifications.
- **Cycle Tracking**: Log flow, mood, symptoms, and notes daily.
- **Smart Predictions**: Local engine calculates next period, fertile window, and current phase.
- **Private & Secure**: Anonymous authentication, biometric lock, and encrypted cloud backups.
- **Multi-language**: Support for English, Melayu, Español, हिन्दी, and العربية (RTL).
- **Offline First**: Full functionality without internet, syncing automatically when online.

## 🛠 Tech Stack

- **Framework**: Flutter 3.24+
- **State Management**: Riverpod 2.x
- **Navigation**: GoRouter 14.x
- **Backend**: Firebase (Auth, Firestore, Storage, FCM)
- **Charts**: fl_chart
- **Local Security**: flutter_secure_storage + local_auth

## 📦 Project Structure

```
lib/
├── core/           # Theme, Router, Providers, Utils
├── features/       # Feature-first modules (Home, Log, Insights, etc.)
├── models/         # Data models
└── l10n/           # Localization files
```

## ⚙️ Setup Instructions

1. **Clone the repository**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Firebase**:
   - Run `flutterfire configure` to link your Firebase project.
   - Ensure Firestore and Auth (Anonymous) are enabled.
4. **Generate Code**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. **Run the app**:
   ```bash
   flutter run
   ```

## 🛡 Privacy Promise

No ads. No selling your data. No judgement. Delete everything anytime. Your data belongs to you.

---
Built with ❤️ for girls and women everywhere.
>
## 🔥 Firestore Data Setup

To populate your Firestore with the necessary dynamic content (symptoms, education, insights), you can use the provided `populate_firestore.py` script or manually add the following structure:

### 1. `config` Collection
- **Document ID**: `symptoms`
  - **Field**: `items` (Array of Maps)
    - `{ "icon": "🔴", "label": "Heavy Flow", "key": "heavy" }`
    - `{ "icon": "😴", "label": "Fatigue", "key": "fatigue" }`
- **Document ID**: `insight_tips`
  - **Field**: `tips` (Array of Maps)
    - `{ "text": "Your average cycle is 28 days. 💕" }`

### 2. `education` Collection
Create documents with:
- `title`: (String) e.g., "Understanding Your Cycle"
- `tag`: (String) e.g., "Basics"
- `tagColor`: (String) e.g., "#F7A8B8"
- `icon`: (String) e.g., "🌸"
- `meta`: (String) e.g., "5 min read"
- `order`: (Number) e.g., 1

### 3. iOS Configuration
The `GoogleService-Info.plist` has been added to `ios/Runner/GoogleService-Info.plist`. **Important**: After pulling the code, you MUST open the project in Xcode, right-click on the `Runner` folder, and select "Add Files to Runner" to include the `.plist` file in the build target.
