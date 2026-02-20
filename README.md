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
