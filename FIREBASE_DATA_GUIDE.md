# MeTrustual Firebase Data Structure & Test Data Guide

This document provides a comprehensive overview of the Firebase Firestore structure and sample test data to help you test all features of the MeTrustual app.

## 1. Firestore Structure Overview

The app uses the following collections and subcollections:

### `users` (Collection)
Each document ID is the user's `uid`.

| Field | Type | Description |
| :--- | :--- | :--- |
| `displayName` | String | User's display name |
| `ageGroup` | String | `teen`, `adult`, or `mature` |
| `region` | String | `asia`, `africa`, `latam`, or `global` |
| `language` | String | `en`, `ms`, `es`, etc. |
| `createdAt` | Timestamp | Account creation date |
| `lifeStage` | String | `period`, `preg`, or `ovul` |
| `isPremium` | Boolean | Premium status (True/False) |
| `premiumSince` | Timestamp | Date when premium was activated |

#### `users/{uid}/journey` (Subcollection)
Contains setup data from the onboarding journey.
- Document `period`:
  - `lastPeriod`: Timestamp/String (Last period start date)
  - `cycleLen`: Number (Average cycle length, e.g., 28)
  - `periodLen`: Number (Average period length, e.g., 5)
  - `flow`: String (e.g., `medium`)
  - `symptoms`: List<String> (Initial symptoms)

#### `users/{uid}/cycles` (Subcollection)
Contains historical cycle data for trend analysis.
- Document ID: Random
  - `startDate`: Timestamp (Start of period)
  - `endDate`: Timestamp (End of period)
  - `length`: Number (Total days of cycle)
  - `notes`: String (Optional)

#### `users/{uid}/logs/period/entries` (Subcollection)
Contains daily logs for the period tracker.
- Document ID: `YYYY-MM-DD`
  - `date`: String (ISO 8601)
  - `flow`: String (`none`, `light`, `medium`, `heavy`)
  - `mood`: String (`happy`, `okay`, `low`, `anxious`, etc.)
  - `symptoms`: List<String>
  - `painLevel`: Number (0-5)
  - `waterGlasses`: Number
  - `sleepHours`: Number
  - `note`: String

---

## 2. Sample Test Data (JSON Format)

You can use this JSON as a template to populate your Firestore.

```json
{
  "users": {
    "test_user_123": {
      "displayName": "Jane Doe",
      "ageGroup": "adult",
      "region": "global",
      "language": "en",
      "createdAt": "2026-01-01T00:00:00Z",
      "lifeStage": "period",
      "isPremium": true,
      "premiumSince": "2026-01-01T00:00:00Z",
      "journey": {
        "period": {
          "lastPeriod": "2026-02-15T00:00:00Z",
          "cycleLen": 28,
          "periodLen": 5,
          "flow": "medium",
          "symptoms": ["cramps", "fatigue"]
        }
      },
      "cycles": {
        "cycle_Jan": {
          "startDate": "2026-01-18T00:00:00Z",
          "endDate": "2026-01-23T00:00:00Z",
          "length": 28,
          "notes": "Normal cycle"
        },
        "cycle_Dec": {
          "startDate": "2025-12-21T00:00:00Z",
          "endDate": "2025-12-26T00:00:00Z",
          "length": 28
        }
      },
      "logs": {
        "period": {
          "entries": {
            "2026-02-15": {
              "date": "2026-02-15T00:00:00Z",
              "flow": "heavy",
              "mood": "low",
              "symptoms": ["cramps", "backache"],
              "painLevel": 3,
              "waterGlasses": 8,
              "sleepHours": 7
            },
            "2026-02-16": {
              "date": "2026-02-16T00:00:00Z",
              "flow": "heavy",
              "mood": "okay",
              "symptoms": ["cramps"],
              "painLevel": 2,
              "waterGlasses": 6,
              "sleepHours": 8
            }
          }
        }
      }
    }
  },
  "config": {
    "appConfig": {
      "maxFailedAttempts": 5,
      "lockoutDurationMinutes": 15
    }
  }
}
```

## 3. How to use this for testing
1. **Mock Premium**: Since `isPremium` is set to `true` in the user document, and the `PremiumService` is now in mock mode (for debug builds), you will have access to all premium features immediately.
2. **Insights Screen**: By populating the `logs` and `cycles` subcollections, the Insights screen will move from "Welcome" state to "Analysing" and finally "Confident" as you add more data.
3. **Calendar**: The `journey/period/lastPeriod` and `cycles` data will populate the calendar with historical periods and future predictions.
