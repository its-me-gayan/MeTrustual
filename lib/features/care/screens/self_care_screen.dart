import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:go_router/go_router.dart';

class SelfCareScreen extends ConsumerStatefulWidget {
  const SelfCareScreen({super.key});

  @override
  ConsumerState<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends ConsumerState<SelfCareScreen> {
  int _affIdx = 0;
  String? _selectedPhase; // Track selected phase

  final Map<String, List<String>> _allAffirmations = {
    'period': [
      'My body is wise and worthy of rest.',
      'I release what no longer serves me.',
      'I honour every phase of my cycle.',
      'I give myself permission to slow down.',
      'My sensitivity is my strength.',
      'I am exactly where I need to be.'
    ],
    'preg': [
      'My body knows exactly how to nurture this life.',
      'I trust the journey, one week at a time.',
      'Every kick is a little love letter.',
      'I am strong, capable, and surrounded by love.',
      'Growing a human is the most magical thing.',
      'I breathe in calm and breathe out fear.'
    ],
    'ovul': [
      'My body is fertile ground for new beginnings.',
      'I work with my cycle, not against it.',
      'I am in tune with my natural rhythm.',
      'My body communicates — I am learning to listen.',
      'I honour the wisdom of my hormones.',
      'Every cycle is a fresh start.'
    ]
  };

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(modeProvider);
    final color = currentMode == 'preg'
        ? const Color(0xFF4A70B0)
        : currentMode == 'ovul'
            ? const Color(0xFF5A8E6A)
            : AppColors.primaryRose;

    // Initialize selected phase on first build
    if (_selectedPhase == null) {
      _selectedPhase = _getDefaultPhase(currentMode);
    }

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Self-Care 🌿',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentMode == 'period'
                    ? 'Your cycle wellness hub'
                    : currentMode == 'preg'
                        ? 'Nurture you & baby 💙'
                        : 'Fertility wellness rituals',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              _buildPhaseStrip(currentMode, color),
              const SizedBox(height: 24),
              _buildCareHero(currentMode, color, _selectedPhase!),
              const SizedBox(height: 24),
              _buildAffirmationCard(currentMode),
              const SizedBox(height: 24),
              _buildBreatheCard(color),
              const SizedBox(height: 24),
              Text(
                "Today's habits",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildHabitRow(color),
              const SizedBox(height: 24),
              Text(
                "Phase rituals for you",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildRituals(currentMode, color, _selectedPhase!),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  "💕 Self-care is not selfish — it's essential",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          AppBottomNav(activeIndex: _getNavIndex(_currentRoute)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String get _currentRoute {
    final String? location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return location ?? '/home';
  }

  int _getNavIndex(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/insights':
        return 1;
      case '/education':
        return 2;
      case '/care':
        return 3;
      default:
        return 0;
    }
  }

  String _getDefaultPhase(String currentMode) {
    if (currentMode == 'period') {
      return 'Follicular';
    } else if (currentMode == 'preg') {
      return '2nd Trim';
    } else {
      return 'Pre-Ovul';
    }
  }

  Widget _buildPhaseStrip(String currentMode, Color color) {
    final List<Map<String, dynamic>> phases = currentMode == 'period'
        ? [
            {'e': '🩸', 'l': 'Menstrual', 'key': 'Menstrual'},
            {'e': '🌱', 'l': 'Follicular', 'key': 'Follicular'},
            {'e': '✨', 'l': 'Ovulatory', 'key': 'Ovulatory'},
            {'e': '🌙', 'l': 'Luteal', 'key': 'Luteal'}
          ]
        : currentMode == 'preg'
            ? [
                {'e': '💙', 'l': '1st Trim', 'key': '1st Trim'},
                {'e': '🌸', 'l': '2nd Trim', 'key': '2nd Trim'},
                {'e': '🌟', 'l': '3rd Trim', 'key': '3rd Trim'},
                {'e': '👼', 'l': 'Newborn', 'key': 'Newborn'}
              ]
            : [
                {'e': '📅', 'l': 'Early', 'key': 'Early'},
                {'e': '🌱', 'l': 'Pre-Ovul', 'key': 'Pre-Ovul'},
                {'e': '🎯', 'l': 'Peak', 'key': 'Peak'},
                {'e': '📉', 'l': 'Post-Ovul', 'key': 'Post-Ovul'}
              ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: phases.map((p) {
          final isActive = _selectedPhase == p['key'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPhase = p['key'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color.withOpacity(0.3) : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(p['e'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    p['l'],
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isActive ? color : AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCareHero(String currentMode, Color color, String selectedPhase) {
    final ritual = _getRitualForPhase(currentMode, selectedPhase);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.05), color.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✦ Today\'s focus',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(ritual['e']!, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            ritual['t']!,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ritual['d']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMid,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: Text(
                'Start Today\'s Ritual ✦',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffirmationCard(String currentMode) {
    final pool = _allAffirmations[currentMode] ?? _allAffirmations['period']!;
    final aff = pool[_affIdx % pool.length];

    return GestureDetector(
      onTap: () {
        setState(() {
          _affIdx = (_affIdx + 1) % pool.length;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              '✦ Daily affirmation — tap to refresh',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '"$aff"',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tap for a new one 🌸',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreatheCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🫁', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4-7-8 Breathing',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Calm your nervous system in 2 minutes',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMid,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Begin →',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHabitCard('💧', '6', 'Glasses', color),
        _buildHabitCard('🌙', '7h', 'Sleep', color),
        _buildHabitCard('🚶', '4k', 'Steps', const Color(0xFFD09040)),
        _buildHabitCard('🥗', '2/3', 'Meals', const Color(0xFF5A8E6A)),
      ],
    );
  }

  Widget _buildHabitCard(String icon, String val, String lbl, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44 - 30) / 4,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            val,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lbl,
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRituals(String currentMode, Color color, String selectedPhase) {
    final ritualData = _getRitualListForPhase(currentMode, selectedPhase);
    return ritualData.map((r) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(r['e']!, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['t']!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r['s']!,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              r['dur']!,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─── PHASE-SPECIFIC DATA ───

  Map<String, String> _getRitualForPhase(String currentMode, String phase) {
    if (currentMode == 'period') {
      switch (phase) {
        case 'Menstrual':
          return {
            'e': '🧘',
            't': 'Menstrual Phase Flow',
            'd': 'Rest and restore — gentle practices to honor your body\'s need for recovery.'
          };
        case 'Follicular':
          return {
            'e': '🧘',
            't': 'Follicular Phase Flow',
            'd': 'Your energy is rising — perfect for gentle stretching & breathwork to welcome the new cycle.'
          };
        case 'Ovulatory':
          return {
            'e': '✨',
            't': 'Ovulatory Phase Energy',
            'd': 'Harness your peak energy — dynamic movement and social connection shine now.'
          };
        case 'Luteal':
          return {
            'e': '🌙',
            't': 'Luteal Phase Calm',
            'd': 'Slow down and nurture — introspective practices support your inner wisdom.'
          };
        default:
          return {
            'e': '🧘',
            't': 'Follicular Phase Flow',
            'd': 'Your energy is rising — perfect for gentle stretching & breathwork to welcome the new cycle.'
          };
      }
    } else if (currentMode == 'preg') {
      switch (phase) {
        case '1st Trim':
          return {
            'e': '💙',
            't': '1st Trimester Wellness',
            'd': 'Nourish and rest — support your body through these early changes with gentle care.'
          };
        case '2nd Trim':
          return {
            'e': '🌸',
            't': '2nd Trimester Wellness',
            'd': 'Your energy is back — nurture your body and bond with baby with these gentle daily rituals.'
          };
        case '3rd Trim':
          return {
            'e': '🌟',
            't': '3rd Trimester Wellness',
            'd': 'Prepare for birth — grounding practices to ease discomfort and build confidence.'
          };
        case 'Newborn':
          return {
            'e': '👼',
            't': 'Postpartum Care',
            'd': 'Recovery and bonding — gentle rituals to support your healing journey.'
          };
        default:
          return {
            'e': '🌸',
            't': '2nd Trimester Wellness',
            'd': 'Your energy is back — nurture your body and bond with baby with these gentle daily rituals.'
          };
      }
    } else {
      switch (phase) {
        case 'Early':
          return {
            'e': '📅',
            't': 'Early Cycle Rituals',
            'd': 'Begin your journey — prepare your body and mind for the fertile window ahead.'
          };
        case 'Pre-Ovul':
          return {
            'e': '🌱',
            't': 'Pre-Ovulation Rituals',
            'd': 'Your fertile window is near — support your hormones with nurturing daily practices.'
          };
        case 'Peak':
          return {
            'e': '🎯',
            't': 'Peak Fertility Rituals',
            'd': 'Your most fertile moment — celebrate your body\'s natural rhythm and power.'
          };
        case 'Post-Ovul':
          return {
            'e': '📉',
            't': 'Post-Ovulation Rituals',
            'd': 'Transition phase — balance and grounding practices as hormones shift.'
          };
        default:
          return {
            'e': '🌱',
            't': 'Pre-Ovulation Rituals',
            'd': 'Your fertile window is near — support your hormones with nurturing daily practices.'
          };
      }
    }
  }

  List<Map<String, String>> _getRitualListForPhase(String currentMode, String phase) {
    if (currentMode == 'period') {
      switch (phase) {
        case 'Menstrual':
          return [
            {'e': '🧘', 't': 'Restorative Yoga', 's': 'Gentle poses to ease cramps', 'dur': '10 min'},
            {'e': '🛁', 't': 'Warm Herbal Bath', 's': 'Relax and restore energy', 'dur': '20 min'},
            {'e': '📓', 't': 'Reflection Journal', 's': 'Explore your inner wisdom', 'dur': '10 min'},
            {'e': '🍵', 't': 'Herbal Tea Ritual', 's': 'Nourish with warming herbs', 'dur': '5 min'},
          ];
        case 'Follicular':
          return [
            {'e': '🧘', 't': 'Morning Yoga — Sun Salutation', 's': 'Energise your body as oestrogen rises', 'dur': '8 min'},
            {'e': '💆', 't': 'Gua Sha Face Massage', 's': 'Lymphatic drainage & glow routine', 'dur': '5 min'},
            {'e': '🛁', 't': 'Rose & Magnesium Bath Soak', 's': 'Relax muscles & ease lingering cramps', 'dur': '20 min'},
            {'e': '📓', 't': 'Cycle Journal Prompt', 's': '"What do I want to invite this cycle?"', 'dur': '5 min'},
          ];
        case 'Ovulatory':
          return [
            {'e': '🏃', 't': 'High-Energy Workout', 's': 'Harness peak energy levels', 'dur': '30 min'},
            {'e': '💃', 't': 'Dance & Movement', 's': 'Express your confidence', 'dur': '15 min'},
            {'e': '🤝', 't': 'Social Connection', 's': 'Reach out to loved ones', 'dur': '30 min'},
            {'e': '✨', 't': 'Confidence Affirmation', 's': 'Celebrate your power', 'dur': '5 min'},
          ];
        case 'Luteal':
          return [
            {'e': '🧘', 't': 'Yin Yoga Flow', 's': 'Deep stretches and release', 'dur': '20 min'},
            {'e': '🎨', 't': 'Creative Expression', 's': 'Art, music, or writing', 'dur': '20 min'},
            {'e': '📚', 't': 'Mindful Reading', 's': 'Nourish your mind', 'dur': '15 min'},
            {'e': '🌙', 't': 'Moon Meditation', 's': 'Connect with inner stillness', 'dur': '10 min'},
          ];
        default:
          return [
            {'e': '🧘', 't': 'Morning Yoga — Sun Salutation', 's': 'Energise your body as oestrogen rises', 'dur': '8 min'},
            {'e': '💆', 't': 'Gua Sha Face Massage', 's': 'Lymphatic drainage & glow routine', 'dur': '5 min'},
          ];
      }
    } else if (currentMode == 'preg') {
      switch (phase) {
        case '1st Trim':
          return [
            {'e': '🧘', 't': 'Gentle Prenatal Yoga', 's': 'Support your changing body', 'dur': '15 min'},
            {'e': '🌿', 't': 'Herbal Support', 's': 'Nourish with pregnancy teas', 'dur': '5 min'},
            {'e': '😴', 't': 'Rest & Restoration', 's': 'Honor your body\'s needs', 'dur': '20 min'},
            {'e': '📓', 't': 'Pregnancy Journal', 's': 'Document your journey', 'dur': '10 min'},
          ];
        case '2nd Trim':
          return [
            {'e': '🧘', 't': 'Prenatal Yoga — Hip Opener', 's': 'Safe stretches for your changing body', 'dur': '12 min'},
            {'e': '🌬️', 't': '4-7-8 Breathing for Calm', 's': 'Reduce pregnancy anxiety & improve sleep', 'dur': '5 min'},
            {'e': '💆', 't': 'Perineal Massage', 's': 'Prepare for birth — from week 34', 'dur': '5 min'},
            {'e': '📓', 't': 'Baby Letter Journal', 's': '"Dear baby, today I felt…"', 'dur': '5 min'},
          ];
        case '3rd Trim':
          return [
            {'e': '🚶', 't': 'Pelvic Floor Walks', 's': 'Prepare for labor', 'dur': '15 min'},
            {'e': '🧘', 't': 'Birth Ball Exercises', 's': 'Ease discomfort and prepare', 'dur': '10 min'},
            {'e': '🌬️', 't': 'Labor Breathing Practice', 's': 'Build confidence for birth', 'dur': '5 min'},
            {'e': '💆', 't': 'Partner Massage', 's': 'Ease tension and connect', 'dur': '15 min'},
          ];
        case 'Newborn':
          return [
            {'e': '🧘', 't': 'Gentle Postpartum Yoga', 's': 'Support your healing', 'dur': '10 min'},
            {'e': '💆', 't': 'Self-Massage & Care', 's': 'Nurture your recovery', 'dur': '10 min'},
            {'e': '🤝', 't': 'Bonding Ritual', 's': 'Connect with your baby', 'dur': '20 min'},
            {'e': '😴', 't': 'Rest When Baby Rests', 's': 'Prioritize your sleep', 'dur': '30 min'},
          ];
        default:
          return [
            {'e': '🧘', 't': 'Prenatal Yoga — Hip Opener', 's': 'Safe stretches for your changing body', 'dur': '12 min'},
            {'e': '🌬️', 't': '4-7-8 Breathing for Calm', 's': 'Reduce pregnancy anxiety & improve sleep', 'dur': '5 min'},
          ];
      }
    } else {
      switch (phase) {
        case 'Early':
          return [
            {'e': '📅', 't': 'Cycle Tracking', 's': 'Begin your observation', 'dur': '5 min'},
            {'e': '🧘', 't': 'Grounding Yoga', 's': 'Center yourself', 'dur': '15 min'},
            {'e': '💧', 't': 'Hydration Ritual', 's': 'Start hydrating well', 'dur': 'All day'},
            {'e': '📓', 't': 'Fertility Journal', 's': 'Note your observations', 'dur': '5 min'},
          ];
        case 'Pre-Ovul':
          return [
            {'e': '🧘', 't': 'Core & Hip Yoga Flow', 's': 'Boost blood flow to reproductive organs', 'dur': '10 min'},
            {'e': '🌿', 't': 'Seed Cycling — Flax & Pumpkin', 's': 'Day 1–14: oestrogen-supporting seeds', 'dur': '2 min'},
            {'e': '🌡️', 't': 'BBT Journaling', 's': 'Log your temp trend and cervical signs', 'dur': '3 min'},
            {'e': '💧', 't': 'Hydration Ritual', 's': 'Cervical mucus loves water — drink up!', 'dur': 'All day'},
          ];
        case 'Peak':
          return [
            {'e': '🎯', 't': 'Peak Fertility Yoga', 's': 'Celebrate your power', 'dur': '15 min'},
            {'e': '💃', 't': 'Sensual Movement', 's': 'Connect with your body', 'dur': '10 min'},
            {'e': '🌿', 't': 'Seed Cycling — Sesame & Sunflower', 's': 'Peak phase seeds', 'dur': '2 min'},
            {'e': '💕', 't': 'Intimacy Ritual', 's': 'Connect with your partner', 'dur': '30 min'},
          ];
        case 'Post-Ovul':
          return [
            {'e': '📉', 't': 'Transition Yoga', 's': 'Balance as hormones shift', 'dur': '12 min'},
            {'e': '🌿', 't': 'Seed Cycling — Sesame & Sunflower', 's': 'Post-peak phase seeds', 'dur': '2 min'},
            {'e': '🧘', 't': 'Grounding Meditation', 's': 'Find your center', 'dur': '10 min'},
            {'e': '📓', 't': 'Cycle Reflection', 's': 'Document your experience', 'dur': '5 min'},
          ];
        default:
          return [
            {'e': '🧘', 't': 'Core & Hip Yoga Flow', 's': 'Boost blood flow to reproductive organs', 'dur': '10 min'},
            {'e': '🌿', 't': 'Seed Cycling — Flax & Pumpkin', 's': 'Day 1–14: oestrogen-supporting seeds', 'dur': '2 min'},
          ];
      }
    }
  }
}
