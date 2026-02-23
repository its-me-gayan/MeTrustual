import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os

# 1. DOWNLOAD YOUR SERVICE ACCOUNT KEY FROM FIREBASE CONSOLE:
# Project Settings -> Service Accounts -> Generate New Private Key
# Rename it to 'serviceAccountKey.json' and place it in the same directory as this script.

def initialize_firebase():
    try:
        # Try to use environment variable if set, otherwise look for local file
        service_account_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', 'serviceAccountKey.json')
        
        if not os.path.exists(service_account_path) and 'GOOGLE_APPLICATION_CREDENTIALS' not in os.environ:
            print("\n✗ Error: 'serviceAccountKey.json' not found.")
            print("Please download your service account key from Firebase Console and place it here.")
            return None

        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        return firestore.client()
    except Exception as e:
        print(f"✗ Error initializing Firebase: {e}")
        return None

def populate_self_care(db):
    print("Starting Firestore population for Self Care...")
    
    data = {
        'period': {
            'Menstrual': {
                'badge': 'PHASE 1: RESTORE', 'emoji': '🩸', 'hero_e': '🩸', 'hero_t': 'Winter Season', 'order': 1,
                'hero_d': 'Focus on rest, warmth, and gentle nourishment. Your body is clearing space for a new cycle.',
                'label': 'Menstrual',
                'rituals': [
                    {'emoji': '🍵', 'title': 'Warm Raspberry Tea', 'subtitle': 'Soothe uterine muscles and relax', 'duration': '5 min', 'order': 1},
                    {'emoji': '🧘', 'title': "Gentle Child's Pose", 'subtitle': 'Release lower back tension', 'duration': '10 min', 'order': 2},
                    {'emoji': '📓', 'title': 'Release Journaling', 'subtitle': "Write down what you're letting go of", 'duration': '5 min', 'order': 3},
                    {'emoji': '🛌', 'title': '9 PM Digital Detox', 'subtitle': 'Early rest to support recovery', 'duration': 'All night', 'order': 4},
                ]
            },
            'Follicular': {
                'badge': 'PHASE 2: RENEW', 'emoji': '🌱', 'hero_e': '🌱', 'hero_t': 'Spring Season', 'order': 2,
                'hero_d': 'Energy is rising. Focus on planning, light movement, and fresh beginnings.',
                'label': 'Follicular',
                'rituals': [
                    {'emoji': '🏃', 'title': 'Brisk Morning Walk', 'subtitle': 'Boost cortisol and wake up your body', 'duration': '20 min', 'order': 1},
                    {'emoji': '🥑', 'title': 'Hormone-Healthy Fats', 'subtitle': 'Support oestrogen production', 'duration': 'Daily', 'order': 2},
                    {'emoji': '🎯', 'title': 'Set 3 Intentions', 'subtitle': 'Plan your cycle goals now', 'duration': '5 min', 'order': 3},
                ]
            },
            'Ovulatory': {
                'badge': 'PHASE 3: RADIATE', 'emoji': '✨', 'hero_e': '✨', 'hero_t': 'Summer Season', 'order': 3,
                'hero_d': 'Your peak energy and confidence. Perfect for socializing and high-intensity movement.',
                'label': 'Ovulatory',
                'rituals': [
                    {'emoji': '💃', 'title': 'High-Energy Movement', 'subtitle': 'Channel your peak vitality', 'duration': '30 min', 'order': 1},
                    {'emoji': '🥗', 'title': 'Raw Veggie Fiber', 'subtitle': 'Help your liver process oestrogen', 'duration': 'Daily', 'order': 2},
                    {'emoji': '✨', 'title': 'Social Connection', 'subtitle': 'Call a friend or attend an event', 'duration': 'Evening', 'order': 3},
                ]
            },
            'Luteal': {
                'badge': 'PHASE 4: REFLECT', 'emoji': '🌙', 'hero_e': '🌙', 'hero_t': 'Autumn Season', 'order': 4,
                'hero_d': 'Turn inward. Focus on completion, nesting, and managing PMS with care.',
                'label': 'Luteal',
                'rituals': [
                    {'emoji': '🧂', 'title': 'Reduce Sodium intake', 'subtitle': 'Minimize bloating and water retention', 'duration': 'Daily', 'order': 1},
                    {'emoji': '🧘', 'title': 'Restorative Yoga', 'subtitle': 'Calm the nervous system', 'duration': '15 min', 'order': 2},
                    {'emoji': '🛀', 'title': 'Epsom Salt Bath', 'subtitle': 'Magnesium for mood and cramps', 'duration': '20 min', 'order': 3},
                ]
            }
        },
        'preg': {
            '1st Trim': {
                'badge': 'FOUNDATION', 'emoji': '💙', 'hero_e': '💙', 'hero_t': 'The Beginning', 'order': 1,
                'hero_d': 'Nurture the seed. Focus on hydration, folic acid, and plenty of rest.',
                'label': '1st Trim',
                'rituals': [
                    {'emoji': '💧', 'title': 'Morning Hydration', 'subtitle': 'Small sips to manage nausea', 'duration': 'Daily', 'order': 1},
                    {'emoji': '💊', 'title': 'Prenatal Vitamin', 'subtitle': 'Essential folic acid & iron', 'duration': '1 min', 'order': 2},
                    {'emoji': '😴', 'title': 'Mid-day Power Nap', 'subtitle': 'Combat fatigue with 20–30 min rest', 'duration': '30 min', 'order': 3},
                ]
            },
            '2nd Trim': {
                'badge': 'BLOOMING', 'emoji': '🌸', 'hero_e': '🌸', 'hero_t': 'The Golden Phase', 'order': 2,
                'hero_d': 'Feel the glow. Focus on bonding, gentle prenatal yoga, and baby prep.',
                'label': '2nd Trim',
                'rituals': [
                    {'emoji': '🧘', 'title': 'Prenatal Yoga', 'subtitle': 'Strengthen and prepare your body', 'duration': '20 min', 'order': 1},
                    {'emoji': '🤰', 'title': 'Belly Massage', 'subtitle': 'Soothe skin and connect with baby', 'duration': '10 min', 'order': 2},
                    {'emoji': '🍎', 'title': 'Iron-Rich Snack', 'subtitle': 'Support blood volume increase', 'duration': 'Daily', 'order': 3},
                ]
            },
            '3rd Trim': {
                'badge': 'PREPARATION', 'emoji': '🌟', 'hero_e': '🌟', 'hero_t': 'The Home Stretch', 'order': 3,
                'hero_d': 'Prepare for arrival. Focus on nesting, birth prep, and managing discomfort.',
                'label': '3rd Trim',
                'rituals': [
                    {'emoji': '🚶', 'title': 'Pelvic Floor Walks', 'subtitle': 'Prepare for labor with gentle movement', 'duration': '15 min', 'order': 1},
                    {'emoji': '🌿', 'title': 'Perineal Massage', 'subtitle': 'Tone the uterus for labor', 'duration': '5 min', 'order': 2},
                    {'emoji': '🦶', 'title': 'Foot Soak & Elevate', 'subtitle': 'Reduce swelling and relax', 'duration': '15 min', 'order': 3},
                ]
            },
            'Newborn': {
                'badge': 'POSTPARTUM', 'emoji': '👼', 'hero_e': '👼', 'hero_t': 'The 4th Trimester', 'order': 4,
                'hero_d': "Healing and bonding. Focus on recovery, support, and learning baby's cues.",
                'label': 'Newborn',
                'rituals': [
                    {'emoji': '🤱', 'title': 'Skin-to-Skin Time', 'subtitle': 'Regulate baby and boost oxytocin', 'duration': '30 min', 'order': 1},
                    {'emoji': '🍲', 'title': 'Warm, Soft Foods', 'subtitle': 'Easy digestion for recovery', 'duration': 'Daily', 'order': 2},
                    {'emoji': '💤', 'title': 'Sleep When Baby Sleeps', 'subtitle': 'Prioritize rest over chores', 'duration': 'Daily', 'order': 3},
                ]
            }
        },
        'ovul': {
            'Early': {
                'badge': 'PREPARATION', 'emoji': '📅', 'hero_e': '📅', 'hero_t': 'Cycle Start', 'order': 1,
                'hero_d': 'Laying the groundwork. Focus on baseline health and cycle tracking.',
                'label': 'Early',
                'rituals': [
                    {'emoji': '🧘', 'title': 'Grounding Yoga', 'subtitle': 'Center yourself', 'duration': '15 min', 'order': 1},
                    {'emoji': '💧', 'title': 'Hydration Ritual', 'subtitle': 'Start hydrating well', 'duration': 'All day', 'order': 2},
                    {'emoji': '📓', 'title': 'Fertility Journal', 'subtitle': 'Note your observations', 'duration': '5 min', 'order': 3},
                ]
            },
            'Pre-Ovul': {
                'badge': 'FERTILE WINDOW', 'emoji': '🌱', 'hero_e': '🌱', 'hero_t': 'Energy Rising', 'order': 2,
                'hero_d': 'Your body is preparing. Focus on cervical mucus signs and vitality.',
                'label': 'Pre-Ovul',
                'rituals': [
                    {'emoji': '🧘', 'title': 'Core & Hip Yoga Flow', 'subtitle': 'Boost blood flow to reproductive organs', 'duration': '10 min', 'order': 1},
                    {'emoji': '🌿', 'title': 'Seed Cycling — Flax & Pumpkin', 'subtitle': 'Day 1–14: oestrogen-supporting seeds', 'duration': '2 min', 'order': 2},
                    {'emoji': '🌡️', 'title': 'BBT Journaling', 'subtitle': 'Log your temp trend and cervical signs', 'duration': '3 min', 'order': 3},
                    {'emoji': '💧', 'title': 'Hydration Ritual', 'subtitle': 'Cervical mucus loves water — drink up!', 'duration': 'All day', 'order': 4},
                ]
            },
            'Peak': {
                'badge': 'OVULATION', 'emoji': '🎯', 'hero_e': '🎯', 'hero_t': 'Peak Fertility', 'order': 3,
                'hero_d': 'The key moment. Focus on timing, BBT confirmation, and wellness.',
                'label': 'Peak',
                'rituals': [
                    {'emoji': '🌡️', 'title': 'Confirm BBT Spike', 'subtitle': 'Temp rises 0.2–0.5°C after ovulation — log it!', 'duration': '2 min', 'order': 1},
                    {'emoji': '💊', 'title': 'Check OPK Result', 'subtitle': 'Look for blazing positive LH strip today', 'duration': '2 min', 'order': 2},
                    {'emoji': '🏃', 'title': 'Light Walk After Intimacy', 'subtitle': 'Gentle movement — no intense exercise today', 'duration': '15 min', 'order': 3},
                    {'emoji': '🫐', 'title': 'Antioxidant-Rich Smoothie', 'subtitle': 'Protect egg quality: berries, CoQ10, maca', 'duration': '5 min', 'order': 4},
                ]
            },
            'Post-Ovul': {
                'badge': 'THE WAIT', 'emoji': '📉', 'hero_e': '📉', 'hero_t': 'Implantation Window', 'order': 4,
                'hero_d': 'Support progesterone. Focus on calm, warmth, and mindful waiting.',
                'label': 'Post-Ovul',
                'rituals': [
                    {'emoji': '🌿', 'title': 'Seed Cycling — Sesame & Sunflower', 'subtitle': 'Switch to Phase 2 seeds for progesterone support', 'duration': 'Daily', 'order': 1},
                    {'emoji': '🧘', 'title': 'Restorative Yoga', 'subtitle': 'Support progesterone with gentle, calming movement', 'duration': '12 min', 'order': 2},
                    {'emoji': '🌡️', 'title': 'Track BBT Stay Elevated', 'subtitle': 'If temp stays high 18+ days — take a test!', 'duration': 'Daily', 'order': 3},
                    {'emoji': '🫖', 'title': 'Raspberry Leaf Tea', 'subtitle': 'Uterine toner to prepare for either outcome', 'duration': '5 min', 'order': 4},
                ]
            }
        }
    }

    base_ref = db.collection('config').document('self_care')

    for mode, phases in data.items():
        print(f"  → Populating mode: {mode}")
        mode_ref = base_ref.collection(mode)
        
        for phase_name, phase_data in phases.items():
            rituals = phase_data.pop('rituals')
            # Set phase document
            mode_ref.document(phase_name).set(phase_data)
            
            # Set rituals subcollection
            rituals_ref = mode_ref.document(phase_name).collection('rituals')
            for i, ritual in enumerate(rituals):
                rituals_ref.document(str(i+1)).set(ritual)
            
            print(f"    ✓ Phase '{phase_name}' and its rituals added.")

    print("\n✓ ALL SELF CARE DATA POPULATED SUCCESSFULLY!")

if __name__ == "__main__":
    client = initialize_firebase()
    if client:
        populate_self_care(client)
