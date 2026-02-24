#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════
#  SOLUNA — Education Articles Firestore Seeder
#
#  Requirements:
#    pip install google-cloud-firestore
#
#  Setup:
#    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
#    python3 seed_education.py
# ═══════════════════════════════════════════════════════════════

from google.cloud import firestore
from datetime import datetime, timezone
import os
import sys

# ── Init ────────────────────────────────────────────────────────
if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
    print("❌  Set GOOGLE_APPLICATION_CREDENTIALS to your serviceAccountKey.json path")
    print("    export GOOGLE_APPLICATION_CREDENTIALS='/path/to/serviceAccountKey.json'")
    sys.exit(1)

db = firestore.Client()

NOW = datetime.now(timezone.utc)
COLLECTION = "education_articles"

# ═══════════════════════════════════════════════════════════════
#  ARTICLES DATA
# ═══════════════════════════════════════════════════════════════
articles = [

    # ──────────────────────────────────────
    #  🌸 PUBERTY
    # ──────────────────────────────────────
    {
        "icon": "🌸",
        "tag": "puberty",
        "tagColor": "#F7A8B8",
        "title": "Your First Period: What to Expect",
        "meta": "Everything you need to know before it arrives",
        "readTime": "5 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 0,
        "language": "en",
        "keyPoints": [
            "Average age for a first period is 12–13, but 9–16 is completely normal",
            "Your first period may be light, spotty, or irregular — that's okay",
            "Periods can be irregular for the first 1–2 years",
            "Stock your bag with a pad or liner before it comes",
        ],
        "body": (
            "## Your first period (menarche) 💕\n\n"
            "Your first period — called **menarche** — is one of the most significant signs that your body is growing up.\n\n"
            "### When will it come?\n"
            "Most girls get their first period between **9 and 16 years old**. You'll likely see signs of puberty about **2 years before** your period arrives.\n\n"
            "### What will it look like?\n"
            "It can be spotty, very light, or darker brown in colour — old blood is often brown, not bright red.\n\n"
            "### Will it hurt?\n"
            "Some girls feel cramps; others feel nothing. A warm heat pad and ibuprofen usually help.\n\n"
            "### Getting prepared 🎒\n"
            "Keep a **pad** or **panty liner** in your school bag. You won't always know when it's coming. You've got this. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🧬",
        "tag": "puberty",
        "tagColor": "#F7A8B8",
        "title": "Hormones 101: The Chemicals Behind Your Cycle",
        "meta": "Oestrogen, progesterone and LH explained simply",
        "readTime": "4 min read",
        "mode": ["period", "ovul", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 1,
        "language": "en",
        "keyPoints": [
            "4 key hormones drive your cycle: oestrogen, progesterone, FSH and LH",
            "Oestrogen rises in the first half — boosting energy and mood",
            "Progesterone dominates the second half — causing PMS symptoms",
            "LH triggers ovulation — the release of the egg",
        ],
        "body": (
            "## The hormones behind your cycle 🧬\n\n"
            "### Oestrogen 🌅\n"
            "Rises in the **first half** (days 1–14). Gives you more energy, clearer skin, and a lifted mood.\n\n"
            "### Progesterone 🌙\n"
            "Rises in the **second half** (days 15–28). Causes bloating, cravings, mood dips and fatigue — the driver of PMS.\n\n"
            "### FSH\n"
            "Signals your ovaries to develop a follicle containing an egg.\n\n"
            "### LH ⚡\n"
            "Surges just before ovulation around day 14. This is what OPK tests detect. "
            "Soluna tracks your hormone phase automatically. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "📏",
        "tag": "puberty",
        "tagColor": "#F7A8B8",
        "title": "What Is a 'Normal' Cycle Length?",
        "meta": "Short, long, irregular — what the science says",
        "readTime": "3 min read",
        "mode": ["period", "ovul", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 2,
        "language": "en",
        "keyPoints": [
            "A 'normal' cycle is anywhere from 21 to 35 days",
            "The 28-day average is a myth — most women don't have it",
            "Cycle length can vary month to month by up to 7 days",
            "Irregular cycles for the first 2 years of menstruation are completely normal",
        ],
        "body": (
            "## What is a normal cycle? 📏\n\n"
            "The idea that every woman has a perfect 28-day cycle is a myth.\n\n"
            "Studies of over 600,000 cycles show **21–35 days** is the clinically normal range. "
            "Only about **13% of cycles** are exactly 28 days.\n\n"
            "### When to be concerned\n"
            "Talk to a doctor if cycles are consistently under 21 or over 35 days, "
            "or if you go 90+ days without a period and aren't pregnant.\n\n"
            "Soluna tracks your individual pattern — not a textbook average. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "💧",
        "tag": "puberty",
        "tagColor": "#F7A8B8",
        "title": "Vaginal Discharge: What's Normal?",
        "meta": "The clear, white fluid that arrives before your period",
        "readTime": "4 min read",
        "mode": ["period", "ovul", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 3,
        "language": "en",
        "keyPoints": [
            "Discharge usually begins 6–12 months before your first period",
            "Clear or white, stretchy or creamy discharge is completely normal",
            "Yellow, green, grey, or foul-smelling discharge needs medical attention",
            "Discharge changes throughout your cycle — tracking it reveals your fertile window",
        ],
        "body": (
            "## Vaginal discharge explained 💧\n\n"
            "Discharge is fluid produced by the cervix and vaginal walls to keep the vagina clean.\n\n"
            "### What's normal\n"
            "Clear/watery, white/cream, or stretchy egg-white discharge is all normal.\n\n"
            "### What's NOT normal\n"
            "Seek medical advice if discharge is yellow-green, grey, cottage-cheese lumpy, "
            "foul-smelling, or accompanied by itching or burning.\n\n"
            "During your **fertile window**, discharge becomes clear and stretchy — "
            "a key signal for fertility tracking. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },


    # ──────────────────────────────────────
    #  🧼 HYGIENE
    # ──────────────────────────────────────
    {
        "icon": "🧼",
        "tag": "hygiene",
        "tagColor": "#A8D8B8",
        "title": "Pads, Tampons, Cups & Discs: Your Guide",
        "meta": "How to choose the right period product for you",
        "readTime": "6 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 0,
        "language": "en",
        "keyPoints": [
            "Pads are the easiest starting point — no insertion required",
            "Tampons must be changed every 4–8 hours to prevent TSS",
            "Menstrual cups can last 10 years and are eco-friendly",
            "Period underwear is a great leak-proof backup option",
        ],
        "body": (
            "## Finding the right period product 🧼\n\n"
            "### 🩲 Pads\nBest for beginners and overnight. Change every 3–5 hours.\n\n"
            "### 🌱 Tampons\nIdeal for sports and swimming. **Never leave in more than 8 hours** — TSS risk.\n\n"
            "### 🍵 Menstrual Cups\nSilicone cup worn up to 12 hours. $20–40 upfront, lasts 5–10 years. "
            "Takes 2–3 cycles to get comfortable.\n\n"
            "### 👙 Period Underwear\nBuilt-in absorbent layers. Perfect for light days or as backup.\n\n"
            "One person using disposables generates **130kg of period waste** in a lifetime. "
            "Cups and period underwear make a real difference. 🌍"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🚿",
        "tag": "hygiene",
        "tagColor": "#A8D8B8",
        "title": "How to Actually Clean 'Down There'",
        "meta": "Why soap inside is wrong — and what to do instead",
        "readTime": "3 min read",
        "mode": ["period", "ovul", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 1,
        "language": "en",
        "keyPoints": [
            "The vagina is self-cleaning — it produces discharge to flush itself",
            "Only the external vulva needs washing — warm water is enough",
            "Soap, douches, and scented products disrupt your natural pH",
            "A disrupted pH causes bacterial vaginosis and yeast infections",
        ],
        "body": (
            "## How to wash correctly 🚿\n\n"
            "Your vagina maintains a pH of 3.8–4.5 and cleans itself with discharge.\n\n"
            "**Do NOT:** insert soap, use douches, use scented products inside.\n\n"
            "**DO:** wash the external vulva with warm water daily. "
            "Use unscented gentle soap on the outer lips only. Wear breathable cotton underwear.\n\n"
            "If you notice unusual odour, cottage-cheese discharge, or itching — "
            "these are signs of BV or thrush. Both are easily treated. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🌙",
        "tag": "hygiene",
        "tagColor": "#A8D8B8",
        "title": "Period Hygiene at Night: Staying Leak-Free",
        "meta": "Products and positions for worry-free sleep",
        "readTime": "3 min read",
        "mode": ["period", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 2,
        "language": "en",
        "keyPoints": [
            "Never sleep in a tampon for more than 8 hours due to TSS risk",
            "A long overnight pad worn at a slight angle prevents most leaks",
            "Period underwear + a pad is the best combo for heavy nights",
            "Sleeping on your side in foetal position reduces cramping",
        ],
        "body": (
            "## Leak-free nights 🌙\n\n"
            "**Best overnight products:** Overnight pad (tilted slightly back), "
            "period underwear, or menstrual cup (safe up to 12 hours).\n\n"
            "**Avoid:** Regular tampons overnight — never exceed 8 hours (TSS risk).\n\n"
            "**Protecting your sheets:** Keep a dark towel under you on heavy nights. "
            "Consider a waterproof mattress protector.\n\n"
            "**Position:** Foetal position (side, knees drawn up) reduces uterine pressure and cramping.\n\n"
            "If you leak: soak in **cold water immediately** — never hot, which sets the stain. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🏊",
        "tag": "hygiene",
        "tagColor": "#A8D8B8",
        "title": "Swimming on Your Period: Yes, You Can",
        "meta": "Everything you need to know about water + periods",
        "readTime": "3 min read",
        "mode": ["period", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 3,
        "language": "en",
        "keyPoints": [
            "You absolutely can swim during your period — water pressure temporarily reduces flow",
            "Tampons and menstrual cups are the best options for swimming",
            "Pads absorb water and become useless — don't swim with one",
            "Chlorinated pools are safe during your period",
        ],
        "body": (
            "## Swimming during your period 🏊\n\n"
            "Water pressure reduces flow while submerged — but you still need protection.\n\n"
            "**Best products:** Tampon (change straight after) or menstrual cup (best — 12hr wear).\n\n"
            "**Avoid:** Pads (absorb water immediately), period underwear (not for submersion).\n\n"
            "**Tampon tips:** Insert fresh just before swimming. Change as soon as you get out. "
            "Use the lowest absorbency that works for your flow.\n\n"
            "Chlorine has no negative interaction with menstrual blood. Swim freely. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },


    # ──────────────────────────────────────
    #  ❌ MYTHS
    # ──────────────────────────────────────
    {
        "icon": "❌",
        "tag": "myths",
        "tagColor": "#B8A8F7",
        "title": "7 Period Myths You Were Taught Wrong",
        "meta": "Science debunks the most common misconceptions",
        "readTime": "5 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 0,
        "language": "en",
        "keyPoints": [
            "MYTH: You lose a lot of blood. FACT: Average is only 30–80ml per cycle",
            "MYTH: Periods should be painful. FACT: Severe pain may signal endometriosis",
            "MYTH: You can't get pregnant on your period. FACT: You can",
            "MYTH: PMS is just mood swings. FACT: It's a real hormonal condition",
        ],
        "body": (
            "## 7 period myths — busted ❌\n\n"
            "**Myth 1:** You lose a lot of blood.\n"
            "**Fact:** Average is just **30–80ml** — about 3–6 tablespoons.\n\n"
            "**Myth 2:** Period pain is normal, push through it.\n"
            "**Fact:** Pain stopping daily activities can signal **endometriosis**.\n\n"
            "**Myth 3:** You can't get pregnant on your period.\n"
            "**Fact:** Sperm survive up to 5 days. Short cycles = real risk.\n\n"
            "**Myth 4:** PMS is just being emotional.\n"
            "**Fact:** PMS and PMDD are clinically recognised hormonal conditions.\n\n"
            "**Myth 5:** Periods sync with friends.\n"
            "**Fact:** Debunked. Multiple large studies found no evidence.\n\n"
            "**Myth 6:** Tampons take away your virginity.\n"
            "**Fact:** Virginity relates to sexual activity, not the hymen.\n\n"
            "**Myth 7:** Avoid exercise during your period.\n"
            "**Fact:** Exercise releases endorphins that reduce cramps and lift mood. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🧂",
        "tag": "myths",
        "tagColor": "#B8A8F7",
        "title": "Food Myths: What You Should Actually Eat",
        "meta": "Busting the diet rules around your period",
        "readTime": "4 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 1,
        "language": "en",
        "keyPoints": [
            "Chocolate cravings are linked to real magnesium deficiency",
            "Cold drinks don't make cramps worse — temperature is a myth",
            "Caffeine can worsen cramps by constricting blood vessels",
            "Iron-rich foods help replenish what you lose each cycle",
        ],
        "body": (
            "## Period food myths 🧂\n\n"
            "**Myth:** Cold food and drinks make cramps worse.\n"
            "**Fact:** No scientific evidence. Cramps are caused by prostaglandins, not temperature. "
            "Warm drinks feel soothing because warmth relaxes muscles — that's real.\n\n"
            "**Myth:** Chocolate cravings mean weakness.\n"
            "**Fact:** Real hormonal shifts affect serotonin and magnesium. "
            "Dark chocolate is genuinely helpful — it contains magnesium and boosts serotonin.\n\n"
            "### What actually helps cramps\n"
            "Magnesium, Omega-3s (salmon, walnuts), iron-rich foods, ginger tea.\n\n"
            "### What makes cramps worse\n"
            "Caffeine, excess salt, alcohol, and processed sugar. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🤰",
        "tag": "myths",
        "tagColor": "#B8A8F7",
        "title": "Pregnancy Myths Every Woman Should Know",
        "meta": "Medical facts vs old wives' tales",
        "readTime": "5 min read",
        "mode": ["preg", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 2,
        "language": "en",
        "keyPoints": [
            "MYTH: Heartburn means a hairy baby. FACT: Partly true — same hormones involved",
            "MYTH: You must eat for two. FACT: Only ~300 extra calories/day in 2nd trimester",
            "MYTH: Exercise harms the baby. FACT: 150 mins/week is actively recommended",
            "MYTH: Morning sickness ends at 12 weeks. FACT: Can last all pregnancy for some",
        ],
        "body": (
            "## Pregnancy myths — busted 🤰\n\n"
            "**Heartburn = hairy baby?** Surprisingly, one Johns Hopkins study found a correlation. "
            "But heartburn is primarily caused by relaxin loosening the oesophageal valve.\n\n"
            "**Eating for two?** First trimester: zero extra calories needed. "
            "Second: ~300 extra. Third: ~450. That's a banana and some nuts — not a second meal.\n\n"
            "**Exercise harms the baby?** ACOG recommends 150 mins of moderate exercise per week "
            "for uncomplicated pregnancies. It reduces gestational diabetes and improves mood.\n\n"
            "**Morning sickness ends at 12 weeks?** For most, yes. But 20% of women experience "
            "nausea throughout the entire pregnancy. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🥚",
        "tag": "myths",
        "tagColor": "#B8A8F7",
        "title": "TTC Myths That Might Be Hurting Your Chances",
        "meta": "Fertility misconceptions that waste precious time",
        "readTime": "4 min read",
        "mode": ["ovul", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 3,
        "language": "en",
        "keyPoints": [
            "MYTH: Legs in the air after sex helps. FACT: No evidence supports this",
            "MYTH: You ovulate on day 14. FACT: Most women don't",
            "MYTH: Stress is the main reason you're not pregnant. FACT: Rarely the cause",
            "MYTH: Have sex every day around ovulation. FACT: Every other day is equally effective",
        ],
        "body": (
            "## TTC myths that waste your time 🥚\n\n"
            "**Legs in the air?** No evidence. Sperm enter cervical mucus within seconds "
            "and reach fallopian tubes in minutes regardless of position.\n\n"
            "**Ovulate on day 14?** Fewer than 30% of women have their fertile window on days 10–17. "
            "Use BBT charting and OPK tests to find YOUR day.\n\n"
            "**Just relax and you'll get pregnant?** Extreme stress can theoretically delay ovulation "
            "but rarely causes infertility. If trying 12+ months (6 if over 35) — see a specialist.\n\n"
            "**Sex every day?** Every 1–2 days is equally effective. Daily sex can actually reduce "
            "sperm count in men with borderline motility. 🌿"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },


    # ──────────────────────────────────────
    #  💊 PAIN
    # ──────────────────────────────────────
    {
        "icon": "💊",
        "tag": "pain",
        "tagColor": "#F7C4A8",
        "title": "Why Do Periods Hurt? The Science of Cramps",
        "meta": "Prostaglandins, endometriosis and pain explained",
        "readTime": "4 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 0,
        "language": "en",
        "keyPoints": [
            "Period pain is caused by prostaglandins — chemicals that make your uterus contract",
            "Higher prostaglandin levels = more pain",
            "NSAIDs (ibuprofen) directly block prostaglandin production",
            "Severe pain that gets worse over time can be a sign of endometriosis",
        ],
        "body": (
            "## Why periods hurt 💊\n\n"
            "**Prostaglandins** trigger uterine contractions that shed the lining. "
            "They can temporarily cut off blood supply — causing cramp-like pain.\n\n"
            "### Why ibuprofen works better than paracetamol\n"
            "Ibuprofen **blocks prostaglandin production**. Take it before cramps peak — "
            "ideally the evening before your period starts. Paracetamol only blocks pain signals.\n\n"
            "### Non-medication options\n"
            "Heat pad, light exercise, warm bath, ginger tea, TENS machine.\n\n"
            "### When pain is a warning sign\n"
            "If pain is worsening each cycle, severe enough to miss work, or accompanies "
            "pain during sex or bowel movements — see a doctor. This can be **endometriosis**. 🌸"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🩺",
        "tag": "pain",
        "tagColor": "#F7C4A8",
        "title": "Endometriosis: The Condition Too Often Dismissed",
        "meta": "Symptoms, diagnosis, and what to do if you suspect it",
        "readTime": "6 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 1,
        "language": "en",
        "keyPoints": [
            "Endometriosis affects 1 in 10 women — roughly 190 million worldwide",
            "Average time to diagnosis is 7–10 years",
            "Main symptoms: severe cramping, pain during sex, bowel pain, fatigue",
            "It's not 'just bad periods' — it's a real disease requiring treatment",
        ],
        "body": (
            "## Endometriosis 🩺\n\n"
            "Tissue similar to the uterine lining grows **outside the uterus** — on ovaries, "
            "fallopian tubes, bowel, or bladder. It bleeds every cycle but has nowhere to go, "
            "causing inflammation and scarring.\n\n"
            "**Affects:** 1 in 10 women. Average diagnosis time: **7–10 years**.\n\n"
            "### Key symptoms\n"
            "Severe period pain worsening over time, pain during sex (deep penetration), "
            "pain during bowel movements or urination, heavy periods, chronic fatigue, "
            "difficulty getting pregnant.\n\n"
            "### Getting the care you deserve\n"
            "Track your pain in Soluna and bring data to your appointment. "
            "Ask specifically about endometriosis. Seek a second opinion if dismissed.\n\n"
            "You are not being dramatic. Pain that interferes with your life deserves investigation. 💕"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🌊",
        "tag": "pain",
        "tagColor": "#F7C4A8",
        "title": "PMS vs PMDD: Understanding the Difference",
        "meta": "When premenstrual symptoms become a medical condition",
        "readTime": "4 min read",
        "mode": ["period", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 2,
        "language": "en",
        "keyPoints": [
            "PMS affects up to 75% of menstruating women in mild forms",
            "PMDD is a severe, clinically distinct condition affecting 3–8%",
            "PMDD symptoms include depression, rage, and suicidal ideation",
            "PMDD responds well to treatment — SSRIs, hormonal therapy, dietary changes",
        ],
        "body": (
            "## PMS vs PMDD 🌊\n\n"
            "**PMS** affects up to 75% of women. Symptoms appear 7–14 days before your period "
            "and disappear within 4 days of it starting: bloating, mild mood swings, cravings, fatigue.\n\n"
            "**PMDD** is a severe, DSM-5 recognised condition affecting 3–8% of women. Symptoms are "
            "so severe they impair daily functioning: severe depression, intense rage, panic attacks, "
            "suicidal thoughts, inability to function.\n\n"
            "The key diagnostic marker: symptoms **completely resolve** once menstruation begins.\n\n"
            "### PMDD is treatable\n"
            "SSRIs (luteal-phase dosing), hormonal contraceptives, dietary changes, exercise, CBT.\n\n"
            "You are not crazy. PMDD is a recognised medical condition. 💕"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🤢",
        "tag": "pain",
        "tagColor": "#F7C4A8",
        "title": "Morning Sickness: Managing Nausea in Pregnancy",
        "meta": "Evidence-based relief that actually works",
        "readTime": "4 min read",
        "mode": ["preg"],
        "isPremium": True,
        "isPublished": True,
        "order": 3,
        "language": "en",
        "keyPoints": [
            "Morning sickness affects 70–80% of pregnant women",
            "Caused by rising hCG — typically peaks at 8–10 weeks",
            "Small, frequent meals prevent the empty stomach that worsens nausea",
            "Vitamin B6 + doxylamine is the first-line medical treatment",
        ],
        "body": (
            "## Morning sickness relief 🤢\n\n"
            "Caused by **hCG** peaking around weeks 8–10. Strong nausea is associated with "
            "lower miscarriage rates — it's a sign of robust hormone production.\n\n"
            "### What actually helps\n"
            "Small, frequent meals — empty stomach worsens nausea. Dry crackers before getting up. "
            "Ginger (tea, biscuits, capsules) — shown effective in multiple RCTs. "
            "Fresh air, Sea-Band acupressure wristbands, rest.\n\n"
            "### Medical options\n"
            "Vitamin B6 (first-line, safe), B6 + doxylamine (FDA approved), "
            "ondansetron for severe cases (doctor prescribed).\n\n"
            "### Seek urgent help if\n"
            "You cannot keep fluids down for 24+ hours, are losing weight, or feel faint. "
            "Dehydration in pregnancy is serious. 💙"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },


    # ──────────────────────────────────────
    #  🏥 DOCTOR
    # ──────────────────────────────────────
    {
        "icon": "🏥",
        "tag": "doctor",
        "tagColor": "#A8C8F7",
        "title": "When to See a Doctor About Your Period",
        "meta": "Red flags that shouldn't be ignored",
        "readTime": "4 min read",
        "mode": ["period", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 0,
        "language": "en",
        "keyPoints": [
            "Period pain that stops you functioning normally is a red flag",
            "Periods lasting longer than 7 days warrant investigation",
            "Soaking through a pad or tampon every hour is abnormally heavy",
            "Missing 3+ periods (not pregnant) needs medical evaluation",
        ],
        "body": (
            "## When to see a doctor 🏥\n\n"
            "### 🔴 See a doctor soon if:\n"
            "Period pain stops you attending school or work, bleeding soaks through "
            "a pad/tampon every hour for several hours, period lasts over 7 days, "
            "bleeding between periods or after sex, 3+ missed periods (not pregnant).\n\n"
            "### 🔴 Also see a doctor if:\n"
            "Pain during sex, pain using the toilet during periods, extreme disproportionate fatigue, "
            "worsening pain each cycle, large clots.\n\n"
            "### 🟢 Bring to your appointment:\n"
            "Your Soluna cycle data — length history, pain scores, flow heaviness. "
            "Data makes diagnosis faster and more accurate. 💕"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🔬",
        "tag": "doctor",
        "tagColor": "#A8C8F7",
        "title": "PCOS: Symptoms, Diagnosis & Management",
        "meta": "The most common hormonal disorder you may not know you have",
        "readTime": "7 min read",
        "mode": ["period", "ovul", "all"],
        "isPremium": False,
        "isPublished": True,
        "order": 1,
        "language": "en",
        "keyPoints": [
            "PCOS affects 8–13% of reproductive-age women — extremely common",
            "Diagnosis requires 2 of 3 criteria: irregular cycles, high androgens, polycystic ovaries",
            "Not everyone with PCOS has cysts — the name is misleading",
            "Lifestyle changes (diet + exercise) are the most effective first-line treatment",
        ],
        "body": (
            "## PCOS explained 🔬\n\n"
            "PCOS affects **8–13% of women** of reproductive age — yet up to 70% are undiagnosed. "
            "Despite the name, not everyone with PCOS has cysts. They're actually immature follicles.\n\n"
            "### Rotterdam Diagnostic Criteria (2 of 3):\n"
            "1. Irregular or absent periods (cycles >35 days)\n"
            "2. Elevated androgens — blood test OR symptoms: excess hair, acne, scalp thinning\n"
            "3. Polycystic ovaries on ultrasound\n\n"
            "### Management\n"
            "**Lifestyle (most powerful):** Low-GI diet, regular exercise, 5–10% weight loss "
            "can restore ovulation.\n\n"
            "**Medical:** Combined pill (regulates cycles), Metformin (insulin sensitivity), "
            "Letrozole/Clomiphene (ovulation induction for TTC), Spironolactone (hirsutism).\n\n"
            "Most people with PCOS **can conceive** — often with medical support. 🌿"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "💉",
        "tag": "doctor",
        "tagColor": "#A8C8F7",
        "title": "Your First Gynaecologist Appointment: What to Expect",
        "meta": "A complete guide so you know exactly what will happen",
        "readTime": "5 min read",
        "mode": ["period", "ovul", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 2,
        "language": "en",
        "keyPoints": [
            "There's no 'right age' — go when you have concerns",
            "You'll be asked about your cycle history — bring your Soluna data",
            "A pelvic exam is NOT always done at a first visit",
            "You can ask for a female doctor and bring a support person",
        ],
        "body": (
            "## Your first gynaecologist visit 💉\n\n"
            "### What to bring\n"
            "Your Soluna cycle data: length history, duration, pain scores, heaviness tracking.\n\n"
            "### What will happen\n"
            "**History taking (always):** Last period date, cycle length, pain levels (1–10), "
            "sexual history, family history, medications.\n\n"
            "**Physical exam (if indicated):** External visual exam, speculum exam (to see cervix), "
            "bimanual exam (feeling uterus and ovaries). Not always done at first visit.\n\n"
            "### Your rights\n"
            "Request a female doctor. Bring a support person. Stop the exam at any point. "
            "Ask questions throughout.\n\n"
            "You are your own best advocate. 💕"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },

    {
        "icon": "🧪",
        "tag": "doctor",
        "tagColor": "#A8C8F7",
        "title": "Fertility Testing: What the Numbers Mean",
        "meta": "AMH, FSH, AFC and your ovarian reserve explained",
        "readTime": "5 min read",
        "mode": ["ovul", "all"],
        "isPremium": True,
        "isPublished": True,
        "order": 3,
        "language": "en",
        "keyPoints": [
            "AMH is the most reliable single marker of ovarian reserve",
            "A low AMH does NOT mean you cannot conceive",
            "FSH above 10 IU/L on day 3 suggests diminished ovarian reserve",
            "AFC (Antral Follicle Count) via ultrasound is the most accurate predictor",
        ],
        "body": (
            "## Fertility testing numbers 🧪\n\n"
            "### AMH (Anti-Müllerian Hormone)\n"
            "Most common ovarian reserve marker.\n"
            "> 1.5 ng/mL = Normal | 1.0–1.5 = Low-normal | 0.5–1.0 = Low | < 0.5 = Very low\n\n"
            "**Important:** AMH reflects **quantity, not quality**. "
            "Many women with low AMH conceive naturally.\n\n"
            "### FSH (Day 3)\n"
            "Normal < 10 IU/L | Borderline 10–15 | Elevated > 15 IU/L\n\n"
            "### AFC (Antral Follicle Count)\n"
            "Transvaginal ultrasound. Normal: 15–30 follicles. Low: < 7 total.\n\n"
            "These numbers help you plan — not panic. Even low results don't rule out conception. 🌿"
        ),
        "relatedIds": [],
        "createdAt": NOW,
        "updatedAt": NOW,
    },
]


# ═══════════════════════════════════════════════════════════════
#  SEED
# ═══════════════════════════════════════════════════════════════
def seed():
    col = db.collection(COLLECTION)
    batch = db.batch()

    for article in articles:
        ref = col.document()          # auto-generated document ID
        batch.set(ref, article)

    batch.commit()
    print(f"  Committed {len(articles)} documents in one batch")
    print(f"✅  Seeded {len(articles)} articles → '{COLLECTION}'")

    # Print tag summary
    from collections import Counter
    counts = Counter(a["tag"] for a in articles)
    for tag, count in sorted(counts.items()):
        print(f"   {count} articles  —  tag: {tag}")


if __name__ == "__main__":
    seed()


# ═══════════════════════════════════════════════════════════════
#  FIRESTORE SECURITY RULES  (paste into Firebase Console)
# ═══════════════════════════════════════════════════════════════
#
# rules_version = '2';
# service cloud.firestore {
#   match /databases/{database}/documents {
#     match /education_articles/{articleId} {
#       allow read:  if request.auth != null
#                    && resource.data.isPublished == true;
#       allow write: if request.auth != null
#                    && request.auth.token.admin == true;
#     }
#   }
# }
#
# ═══════════════════════════════════════════════════════════════
#  RECOMMENDED COMPOSITE INDEXES (Firebase Console)
# ═══════════════════════════════════════════════════════════════
#
#  Index 1 — default listing:
#    isPublished ASC, language ASC, order ASC
#
#  Index 2 — category tab filter:
#    isPublished ASC, language ASC, tag ASC, order ASC
#
#  Index 3 — mode filter:
#    isPublished ASC, language ASC, mode ARRAY_CONTAINS, order ASC
#
# ═══════════════════════════════════════════════════════════════
#  UPDATED educationContentProvider QUERY (dynamic_content_provider.dart)
# ═══════════════════════════════════════════════════════════════
#
#  final educationContentProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
#    final locale = ref.watch(localeProvider);
#    final mode   = ref.watch(modeProvider).mode;
#
#    return FirebaseFirestore.instance
#        .collection('education_articles')
#        .where('isPublished', isEqualTo: true)
#        .where('language',    isEqualTo: locale)
#        .where('mode',        arrayContainsAny: [mode, 'all'])
#        .orderBy('order')
#        .snapshots()
#        .map((snap) => snap.docs
#            .map((d) => {...d.data(), 'id': d.id})
#            .toList());
#  });