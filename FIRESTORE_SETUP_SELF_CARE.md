# Firestore Setup Guide for Self Care Page

This document describes the Firestore collection structure needed to support the Self Care page with dynamic data fetching for all 3 profiles.

## Collection Structure

```
config/
  └── self_care/
      ├── period/
      │   ├── Menstrual/
      │   │   ├── badge: "PHASE 1: RESTORE"
      │   │   ├── emoji: "🩸"
      │   │   ├── hero_e: "🩸"
      │   │   ├── hero_t: "Winter Season"
      │   │   ├── hero_d: "Focus on rest, warmth, and gentle nourishment. Your body is clearing space for a new cycle."
      │   │   ├── label: "Menstrual"
      │   │   ├── order: 1
      │   │   └── rituals/
      │   │       ├── 1/
      │   │       │   ├── emoji: "🍵"
      │   │       │   ├── title: "Warm Raspberry Tea"
      │   │       │   ├── subtitle: "Soothe uterine muscles and relax"
      │   │       │   ├── duration: "5 min"
      │   │       │   └── order: 1
      │   │       ├── 2/
      │   │       │   ├── emoji: "🧘"
      │   │       │   ├── title: "Gentle Child's Pose"
      │   │       │   ├── subtitle: "Release lower back tension"
      │   │       │   ├── duration: "10 min"
      │   │       │   └── order: 2
      │   │       └── ...
      │   ├── Follicular/
      │   ├── Ovulatory/
      │   └── Luteal/
      ├── preg/
      │   ├── 1st Trim/
      │   ├── 2nd Trim/
      │   ├── 3rd Trim/
      │   └── Newborn/
      └── ovul/
          ├── Early/
          ├── Pre-Ovul/
          ├── Peak/
          └── Post-Ovul/
```

## Detailed Schema

### Phase Document (e.g., `config/self_care/period/Menstrual`)

| Field | Type | Description |
|-------|------|-------------|
| `badge` | String | Badge text (e.g., "PHASE 1: RESTORE") |
| `emoji` | String | Phase emoji for the phase strip (e.g., "🩸") |
| `hero_e` | String | Large emoji for the hero section (e.g., "🩸") |
| `hero_t` | String | Hero title (e.g., "Winter Season") |
| `hero_d` | String | Hero description (e.g., "Focus on rest...") |
| `label` | String | Phase label (e.g., "Menstrual") |
| `order` | Number | Order in the phase strip (1-4) |

### Ritual Document (e.g., `config/self_care/period/Menstrual/rituals/1`)

| Field | Type | Description |
|-------|------|-------------|
| `emoji` | String | Ritual emoji (e.g., "🍵") |
| `title` | String | Ritual title (e.g., "Warm Raspberry Tea") |
| `subtitle` | String | Ritual description (e.g., "Soothe uterine muscles and relax") |
| `duration` | String | Duration (e.g., "5 min", "Daily", "All night") |
| `order` | Number | Order in the ritual list (1+) |

## Sample Data for Period Profile

### Menstrual Phase

**Phase Document:**
```json
{
  "badge": "PHASE 1: RESTORE",
  "emoji": "🩸",
  "hero_e": "🩸",
  "hero_t": "Winter Season",
  "hero_d": "Focus on rest, warmth, and gentle nourishment. Your body is clearing space for a new cycle.",
  "label": "Menstrual",
  "order": 1
}
```

**Rituals:**
1. Warm Raspberry Tea (5 min)
2. Gentle Child's Pose (10 min)
3. Release Journaling (5 min)
4. 9 PM Digital Detox (All night)

### Follicular Phase

**Phase Document:**
```json
{
  "badge": "PHASE 2: RENEW",
  "emoji": "🌱",
  "hero_e": "🌱",
  "hero_t": "Spring Season",
  "hero_d": "Energy is rising. Focus on planning, light movement, and fresh beginnings.",
  "label": "Follicular",
  "order": 2
}
```

**Rituals:**
1. Brisk Morning Walk (20 min)
2. Hormone-Healthy Fats (Daily)
3. Set 3 Intentions (5 min)

### Ovulatory Phase

**Phase Document:**
```json
{
  "badge": "PHASE 3: RADIATE",
  "emoji": "✨",
  "hero_e": "✨",
  "hero_t": "Summer Season",
  "hero_d": "Your peak energy and confidence. Perfect for socializing and high-intensity movement.",
  "label": "Ovulatory",
  "order": 3
}
```

**Rituals:**
1. High-Energy Movement (30 min)
2. Raw Veggie Fiber (Daily)
3. Social Connection (Evening)

### Luteal Phase

**Phase Document:**
```json
{
  "badge": "PHASE 4: REFLECT",
  "emoji": "🌙",
  "hero_e": "🌙",
  "hero_t": "Autumn Season",
  "hero_d": "Turn inward. Focus on completion, nesting, and managing PMS with care.",
  "label": "Luteal",
  "order": 4
}
```

**Rituals:**
1. Reduce Sodium intake (Daily)
2. Restorative Yoga (15 min)
3. Epsom Salt Bath (20 min)

## Sample Data for Pregnancy Profile

### 1st Trimester

**Phase Document:**
```json
{
  "badge": "FOUNDATION",
  "emoji": "💙",
  "hero_e": "💙",
  "hero_t": "The Beginning",
  "hero_d": "Nurture the seed. Focus on hydration, folic acid, and plenty of rest.",
  "label": "1st Trim",
  "order": 1
}
```

**Rituals:**
1. Morning Hydration (Daily)
2. Prenatal Vitamin (1 min)
3. Mid-day Power Nap (30 min)

### 2nd Trimester

**Phase Document:**
```json
{
  "badge": "BLOOMING",
  "emoji": "🌸",
  "hero_e": "🌸",
  "hero_t": "The Golden Phase",
  "hero_d": "Feel the glow. Focus on bonding, gentle prenatal yoga, and baby prep.",
  "label": "2nd Trim",
  "order": 2
}
```

**Rituals:**
1. Prenatal Yoga (20 min)
2. Belly Massage (10 min)
3. Iron-Rich Snack (Daily)

### 3rd Trimester

**Phase Document:**
```json
{
  "badge": "PREPARATION",
  "emoji": "🌟",
  "hero_e": "🌟",
  "hero_t": "The Home Stretch",
  "hero_d": "Prepare for arrival. Focus on nesting, birth prep, and managing discomfort.",
  "label": "3rd Trim",
  "order": 3
}
```

**Rituals:**
1. Pelvic Floor Walks (15 min)
2. Perineal Massage (5 min)
3. Foot Soak & Elevate (15 min)

### Newborn

**Phase Document:**
```json
{
  "badge": "POSTPARTUM",
  "emoji": "👼",
  "hero_e": "👼",
  "hero_t": "The 4th Trimester",
  "hero_d": "Healing and bonding. Focus on recovery, support, and learning baby's cues.",
  "label": "Newborn",
  "order": 4
}
```

**Rituals:**
1. Skin-to-Skin Time (30 min)
2. Warm, Soft Foods (Daily)
3. Sleep When Baby Sleeps (Daily)

## Sample Data for Ovulation Profile

### Early

**Phase Document:**
```json
{
  "badge": "PREPARATION",
  "emoji": "📅",
  "hero_e": "📅",
  "hero_t": "Cycle Start",
  "hero_d": "Laying the groundwork. Focus on baseline health and cycle tracking.",
  "label": "Early",
  "order": 1
}
```

**Rituals:**
1. Grounding Yoga (15 min)
2. Hydration Ritual (All day)
3. Fertility Journal (5 min)

### Pre-Ovulation

**Phase Document:**
```json
{
  "badge": "FERTILE WINDOW",
  "emoji": "🌱",
  "hero_e": "🌱",
  "hero_t": "Energy Rising",
  "hero_d": "Your body is preparing. Focus on cervical mucus signs and vitality.",
  "label": "Pre-Ovul",
  "order": 2
}
```

**Rituals:**
1. Core & Hip Yoga Flow (10 min)
2. Seed Cycling — Flax & Pumpkin (2 min)
3. BBT Journaling (3 min)
4. Hydration Ritual (All day)

### Peak (Ovulation)

**Phase Document:**
```json
{
  "badge": "OVULATION",
  "emoji": "🎯",
  "hero_e": "🎯",
  "hero_t": "Peak Fertility",
  "hero_d": "The key moment. Focus on timing, BBT confirmation, and wellness.",
  "label": "Peak",
  "order": 3
}
```

**Rituals:**
1. Confirm BBT Spike (2 min)
2. Check OPK Result (2 min)
3. Light Walk After Intimacy (15 min)
4. Antioxidant-Rich Smoothie (5 min)

### Post-Ovulation

**Phase Document:**
```json
{
  "badge": "THE WAIT",
  "emoji": "📉",
  "hero_e": "📉",
  "hero_t": "Implantation Window",
  "hero_d": "Support progesterone. Focus on calm, warmth, and mindful waiting.",
  "label": "Post-Ovul",
  "order": 4
}
```

**Rituals:**
1. Seed Cycling — Sesame & Sunflower (Daily)
2. Restorative Yoga (12 min)
3. Track BBT Stay Elevated (Daily)
4. Raspberry Leaf Tea (5 min)

## Implementation Notes

1. **Fallback Data**: The app includes hardcoded fallback data for all phases and rituals. If Firestore data is unavailable, the app will automatically use the fallback data.

2. **Dynamic Loading**: The `self_care_provider.dart` file contains Riverpod providers that fetch data from Firestore. The providers handle loading and error states gracefully.

3. **AI Affirmations**: The affirmation service generates unique affirmations based on the user's selected profile and phase. Affirmations are cached locally to ensure one affirmation per day.

4. **Phase Switching**: When users switch between phases, the affirmation is automatically regenerated for that phase.

## Firestore Security Rules

Ensure your Firestore security rules allow read access to the `config` collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow public read access to config
    match /config/{document=**} {
      allow read: if true;
    }
    
    // Restrict other collections as needed
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

## How to Upload Data to Firestore

You can upload this data using:
1. Firebase Console (UI)
2. Firebase Admin SDK (programmatic)
3. Firestore CLI
4. Your app's admin panel (if implemented)

Example using Firebase Console:
1. Go to Firestore Database
2. Create collection: `config`
3. Create document: `self_care`
4. Create subcollections for each profile: `period`, `preg`, `ovul`
5. Add phase documents and their ritual subcollections
