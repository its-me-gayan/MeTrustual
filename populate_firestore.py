import firebase_admin
from firebase_admin import credentials, firestore
import os

# Path to service account key - assuming user will provide or using default if possible
# Since I don't have the service account key, I'll provide a script the user can run
# OR I'll use the firebase-admin library with the project ID from the plist

print("Starting Firestore population script...")

# Note: In a real environment, this would need a service account JSON.
# I will provide the data structure and the script.
# User can run this locally with their service account.

data = {
    "config": [
        {
            "id": "symptoms",
            "items": [
                {"icon": "🔴", "label": "Heavy Flow", "key": "heavy"},
                {"icon": "🟠", "label": "Medium Flow", "key": "medium"},
                {"icon": "🟡", "label": "Light Flow", "key": "light"},
                {"icon": "😫", "label": "Cramps", "key": "cramps"},
                {"icon": "😴", "label": "Fatigue", "key": "fatigue"},
                {"icon": "🤕", "label": "Headache", "key": "headache"},
                {"icon": "😊", "label": "Good Mood", "key": "good_mood"},
                {"icon": "😔", "label": "Low Mood", "key": "low_mood"}
            ]
        },
        {
            "id": "insight_tips",
            "tips": [
                {"text": "Your average cycle is 28 days. Your body knows what it's doing 💕"},
                {"text": "Drink plenty of water today to stay hydrated! 💧"},
                {"text": "Gentle stretching can help relieve cramps. 🧘‍♀️"},
                {"text": "You're in your fertile window. Take care! 🌿"}
            ]
        }
    ],
    "education": [
        {
            "title": "Understanding Your Cycle",
            "tag": "Basics",
            "tagColor": "#F7A8B8",
            "icon": "🌸",
            "meta": "5 min read",
            "order": 1
        },
        {
            "title": "Hygiene Tips",
            "tag": "Hygiene",
            "tagColor": "#A8D0B8",
            "icon": "🧼",
            "meta": "3 min read",
            "order": 2
        },
        {
            "title": "Period Myths Debunked",
            "tag": "Myths",
            "tagColor": "#C8B0E0",
            "icon": "❌",
            "meta": "7 min read",
            "order": 3
        }
    ]
}

print("Sample data defined. To populate Firestore:")
print("1. Download your Service Account JSON from Firebase Console.")
print("2. Run: pip install firebase-admin")
print("3. Use this script to upload the data.")

# I'll also write a README section for this
