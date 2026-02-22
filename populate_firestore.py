import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

print("Starting Firestore population script for MeTrustual...")

# Initialize Firebase Admin SDK
# The credentials should be set via GOOGLE_APPLICATION_CREDENTIALS environment variable
# or you can pass the path directly
try:
    # Try to initialize with default credentials
    if not firebase_admin.get_app():
        firebase_admin.initialize_app()
except ValueError:
    # App already initialized
    pass

db = firestore.client()

# Define journey steps for all three modes
journey_steps = {
    "period": [
        {
            "icon": "🩸",
            "q": "When did your last period start?",
            "sub": "This helps us predict your next period and fertile window accurately.",
            "type": "date",
            "key": "lastPeriod",
            "required": False,
            "skip": "Not sure / this is my first time tracking"
        },
        {
            "icon": "📅",
            "q": "How long is your cycle usually?",
            "sub": "Day 1 of one period to Day 1 of the next. Most cycles are 21–35 days.",
            "type": "stepper",
            "key": "cycleLen",
            "min": 18,
            "max": 45,
            "def": 28,
            "unit": "days",
            "skip": "Not sure yet — we'll learn!"
        },
        {
            "icon": "🗓️",
            "q": "How many days does your period last?",
            "sub": "Include light spotting days. Most periods last 3–7 days.",
            "type": "stepper",
            "key": "periodLen",
            "min": 1,
            "max": 10,
            "def": 5,
            "unit": "days"
        },
        {
            "icon": "💧",
            "q": "How would you describe your usual flow?",
            "sub": "Helps us give you better predictions and product recommendations.",
            "type": "chips-single",
            "key": "flow",
            "required": True,
            "opts": [
                {"e": "💧", "l": "Light", "v": "light"},
                {"e": "🟠", "l": "Medium", "v": "medium"},
                {"e": "🔴", "l": "Heavy", "v": "heavy"},
                {"e": "🔀", "l": "Varies", "v": "varies"}
            ]
        },
        {
            "icon": "🌀",
            "q": "Symptoms you often get?",
            "sub": "Select all that apply — we'll personalise your care tips each phase.",
            "type": "chips-multi",
            "key": "symptoms",
            "opts": [
                {"e": "🌀", "l": "Cramps"},
                {"e": "🤕", "l": "Headache"},
                {"e": "😴", "l": "Fatigue"},
                {"e": "🤢", "l": "Nausea"},
                {"e": "🌊", "l": "Bloating"},
                {"e": "💆", "l": "Back Pain"},
                {"e": "🍫", "l": "Cravings"},
                {"e": "😤", "l": "Mood Swings"},
                {"e": "✨", "l": "None of these"}
            ]
        }
    ],
    "preg": [
        {
            "icon": "🤰",
            "q": "Are you currently pregnant?",
            "sub": "This helps us set up the right tracker for you. No judgement either way.",
            "type": "chips-big-single",
            "key": "isPreg",
            "required": True,
            "opts": [
                {"e": "✅", "l": "Yes, I'm pregnant!", "v": "yes"},
                {"e": "🤔", "l": "I think I might be", "v": "maybe"},
                {"e": "🔄", "l": "Actually, I'm not — switch tracker", "v": "switch", "special": True}
            ],
            "warn": "You can switch back to Period or Ovulation tracker anytime from your home screen."
        },
        {
            "icon": "📅",
            "q": "Do you know your due date?",
            "sub": "If yes, enter it. If not, enter your last period start date and we'll calculate.",
            "type": "due-date",
            "key": "dueDate",
            "required": False
        },
        {
            "icon": "👶",
            "q": "Is this your first pregnancy?",
            "sub": "This personalises your week-by-week tips and what to expect.",
            "type": "chips-big-single",
            "key": "firstPreg",
            "required": True,
            "opts": [
                {"e": "🌱", "l": "Yes — my first!", "v": "first"},
                {"e": "👧", "l": "I have one child", "v": "second"},
                {"e": "👨‍👩‍👧‍👦", "l": "Two or more children", "v": "multiple"}
            ]
        },
        {
            "icon": "🩺",
            "q": "Any conditions to track together?",
            "sub": "Optional — select any for extra personalised support and reminders.",
            "type": "chips-multi",
            "key": "conditions",
            "opts": [
                {"e": "🩺", "l": "Gestational Diabetes"},
                {"e": "💓", "l": "High Blood Pressure"},
                {"e": "🤢", "l": "Severe Morning Sickness"},
                {"e": "🩸", "l": "Anaemia"},
                {"e": "🧠", "l": "Prenatal Anxiety"},
                {"e": "😴", "l": "Sleep Issues"},
                {"e": "✨", "l": "All good — none"}
            ]
        },
        {
            "icon": "💙",
            "q": "What support do you want from us?",
            "sub": "We'll send you the content that matters most. Adjust anytime.",
            "type": "chips-multi",
            "key": "support",
            "opts": [
                {"e": "📋", "l": "Weekly baby updates"},
                {"e": "🩺", "l": "Appointment reminders"},
                {"e": "👶", "l": "Kick counter alerts"},
                {"e": "🌿", "l": "Nutrition & wellness tips"},
                {"e": "🧘", "l": "Mental health & mindfulness"},
                {"e": "📖", "l": "Birth & newborn prep"}
            ]
        }
    ],
    "ovul": [
        {
            "icon": "🌿",
            "q": "What's your main goal?",
            "sub": "This shapes your insights, alerts, and what tools we highlight for you.",
            "type": "chips-big-single",
            "key": "goal",
            "required": True,
            "opts": [
                {"e": "👶", "l": "Trying to conceive (TTC)", "v": "ttc"},
                {"e": "🌿", "l": "Natural family planning", "v": "nfp"},
                {"e": "🔬", "l": "Understanding my body & cycle", "v": "understand"}
            ]
        },
        {
            "icon": "📅",
            "q": "When did your last period start?",
            "sub": "We calculate your fertile window from this. Ovulation is usually ~14 days before your next period.",
            "type": "date",
            "key": "lastPeriod",
            "required": True,
            "skip": "Skip for now"
        },
        {
            "icon": "🔁",
            "q": "How long is your cycle usually?",
            "sub": "Knowing this makes ovulation predictions much more accurate.",
            "type": "stepper",
            "key": "cycleLen",
            "min": 18,
            "max": 45,
            "def": 28,
            "unit": "days",
            "skip": "Not sure yet"
        },
        {
            "icon": "🌡️",
            "q": "What do you currently track?",
            "sub": "Select all that apply — we'll guide you on using each method together.",
            "type": "chips-multi",
            "key": "methods",
            "opts": [
                {"e": "🌡️", "l": "BBT (Basal Body Temp)"},
                {"e": "💊", "l": "OPK / LH Test Strips"},
                {"e": "💧", "l": "Cervical Mucus"},
                {"e": "📅", "l": "Period dates only"},
                {"e": "🩸", "l": "Mid-cycle spotting"},
                {"e": "🆕", "l": "Nothing yet — just starting!"}
            ]
        },
        {
            "icon": "🔔",
            "q": "How should we alert you?",
            "sub": "We only send what you choose. You can change this anytime.",
            "type": "chips-multi",
            "key": "alerts",
            "opts": [
                {"e": "🟢", "l": "Fertile window opens"},
                {"e": "🎯", "l": "Peak ovulation day"},
                {"e": "📉", "l": "Fertile window closing"},
                {"e": "📅", "l": "Period due reminder"},
                {"e": "🌡️", "l": "BBT reminder each morning"},
                {"e": "💊", "l": "OPK test reminder"}
            ]
        }
    ]
}

def populate_journey_steps():
    """Populate journey steps into Firestore"""
    try:
        for mode, steps in journey_steps.items():
            print(f"\nPopulating journey steps for mode: {mode}")
            
            # Create a document in the 'journeys' collection
            db.collection('journeys').document(mode).set({
                'steps': steps,
                'mode': mode,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            
            print(f"✓ Successfully populated {len(steps)} steps for {mode} mode")
        
        print("\n✓ All journey steps have been successfully populated to Firestore!")
        return True
    except Exception as e:
        print(f"✗ Error populating journey steps: {e}")
        return False

def populate_config_data():
    """Populate configuration data (symptoms, tips, etc.)"""
    try:
        config_data = {
            "symptoms": [
                {"icon": "🔴", "label": "Heavy Flow", "key": "heavy"},
                {"icon": "🟠", "label": "Medium Flow", "key": "medium"},
                {"icon": "🟡", "label": "Light Flow", "key": "light"},
                {"icon": "😫", "label": "Cramps", "key": "cramps"},
                {"icon": "😴", "label": "Fatigue", "key": "fatigue"},
                {"icon": "🤕", "label": "Headache", "key": "headache"},
                {"icon": "😊", "label": "Good Mood", "key": "good_mood"},
                {"icon": "😔", "label": "Low Mood", "key": "low_mood"}
            ],
            "insight_tips": [
                {"text": "Your average cycle is 28 days. Your body knows what it's doing 💕"},
                {"text": "Drink plenty of water today to stay hydrated! 💧"},
                {"text": "Gentle stretching can help relieve cramps. 🧘‍♀️"},
                {"text": "You're in your fertile window. Take care! 🌿"}
            ]
        }
        
        print("\nPopulating configuration data...")
        db.collection('config').document('data').set(config_data)
        print("✓ Configuration data populated successfully!")
        return True
    except Exception as e:
        print(f"✗ Error populating config data: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("MeTrustual Firestore Population Script")
    print("=" * 60)
    
    # Check if Firebase is initialized
    try:
        app = firebase_admin.get_app()
        print("✓ Firebase initialized successfully")
    except ValueError:
        print("✗ Firebase not initialized. Please ensure GOOGLE_APPLICATION_CREDENTIALS is set.")
        print("  To set it up:")
        print("  1. Download your service account JSON from Firebase Console")
        print("  2. Set: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json")
        exit(1)
    
    # Populate data
    success = populate_journey_steps()
    success = populate_config_data() and success
    
    if success:
        print("\n" + "=" * 60)
        print("✓ Firestore population completed successfully!")
        print("=" * 60)
    else:
        print("\n" + "=" * 60)
        print("✗ Firestore population encountered errors")
        print("=" * 60)
