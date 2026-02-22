import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class SelfCareScreen extends ConsumerStatefulWidget {
  const SelfCareScreen({super.key});

  @override
  ConsumerState<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends ConsumerState<SelfCareScreen> {
  int _affIdx = 0;
  String? _selectedPhase;

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
    if (currentMode == 'period') return 'Follicular';
    if (currentMode == 'preg') return '2nd Trim';
    return 'Pre-Ovul';
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
    final data = _getPhaseData(currentMode, selectedPhase);
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
              data['badge']!,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(data['hero_e']!, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            data['hero_t']!,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data['hero_d']!,
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
              onPressed: () => _startRitual(currentMode, selectedPhase),
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
          const SizedBox(height: 20),
          _buildTipStrip(data),
        ],
      ),
    );
  }

  Widget _buildTipStrip(Map<String, String> data) {
    return Column(
      children: [
        _buildTipItem('💭', data['mood']!, const Color(0xFFE8F0FE), const Color(0xFF4A70B0)),
        const SizedBox(height: 8),
        _buildTipItem('🍽️', data['food']!, const Color(0xFFF0FAF4), const Color(0xFF5A8E6A)),
        const SizedBox(height: 8),
        _buildTipItem('⚠️', data['avoid']!, const Color(0xFFFFF5F6), const Color(0xFFD97B8A)),
      ],
    );
  }

  Widget _buildTipItem(String icon, String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textCol,
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
    return GestureDetector(
      onTap: () => _startRitual(ref.read(modeProvider), _selectedPhase!),
      child: Container(
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
                    'Guided Ritual Session',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Step-by-step with timers — tap to start',
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

  void _startRitual(String mode, String phase) {
    final rituals = _getRitualListForPhase(mode, phase);
    final color = mode == 'preg'
        ? const Color(0xFF4A70B0)
        : mode == 'ovul'
            ? const Color(0xFF5A8E6A)
            : AppColors.primaryRose;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RitualOverlay(rituals: rituals, color: color),
    );
  }

  Map<String, String> _getPhaseData(String mode, String phase) {
    if (mode == 'period') {
      switch (phase) {
        case 'Menstrual':
          return {
            'badge': '🩸 Days 1–5',
            'hero_e': '🛌',
            'hero_t': 'Rest & Restore',
            'hero_d': 'Your body is shedding. Honour it with deep rest, warmth, and nourishment. This is not laziness — this is medicine.',
            'mood': '🌧️ Low energy expected — be gentle',
            'food': 'Iron-rich: lentils, spinach, dark chocolate 🍫',
            'avoid': 'Avoid intense cardio, cold drinks & caffeine'
          };
        case 'Follicular':
          return {
            'badge': '🌱 Days 6–13',
            'hero_e': '🧘',
            'hero_t': 'Rise & Bloom',
            'hero_d': 'Oestrogen is climbing. Your energy, creativity and social drive are building. The best time to start new things.',
            'mood': '⬆️ Energy rising — great for new goals',
            'food': 'Protein & complex carbs: eggs, oats, avocado 🥑',
            'avoid': 'Don\'t overcommit — energy hasn\'t peaked yet'
          };
        case 'Ovulatory':
          return {
            'badge': '✨ Days 14–16',
            'hero_e': '🌟',
            'hero_t': 'Peak Power Day',
            'hero_d': 'You\'re at your most magnetic. Oestrogen + testosterone are peaking — socialise, create, and tackle your hardest tasks.',
            'mood': '✨ Peak energy & confidence — shine!',
            'food': 'Antioxidants: berries, flaxseeds, leafy greens 🫐',
            'avoid': 'Watch for ovulation pain (Mittelschmerz)'
          };
        case 'Luteal':
          return {
            'badge': '🌙 Days 17–28',
            'hero_e': '🌙',
            'hero_t': 'Wind Down & Nest',
            'hero_d': 'Progesterone is rising. Your body is preparing. Cravings, mood dips and fatigue are normal — meet them with kindness.',
            'mood': '🌊 Moody waves — journaling helps a lot',
            'food': 'Progesterone support: vitamin B6, magnesium 🥜',
            'avoid': 'Reduce salt & caffeine to ease bloating'
          };
      }
    } else if (mode == 'preg') {
      switch (phase) {
        case '1st Trim':
          return {
            'badge': '🌱 Weeks 1–12',
            'hero_e': '🌱',
            'hero_t': 'The Foundation',
            'hero_d': 'Your body is working overtime to build a life. Nausea and fatigue are signs of a strong pregnancy. Go slow.',
            'mood': '😴 Extreme fatigue — nap whenever you can',
            'food': 'Folic acid & ginger for nausea 🫚',
            'avoid': 'Avoid raw fish, unpasteurized cheese & high heat'
          };
        case '2nd Trim':
          return {
            'badge': '🌸 Weeks 13–27',
            'hero_e': '🤰',
            'hero_t': 'The Golden Phase',
            'hero_d': 'Energy returns and the "glow" begins. A beautiful time to bond with baby and stay active with gentle movement.',
            'mood': '😊 Mood stabilizing — enjoy the energy!',
            'food': 'Calcium & Vitamin D for baby\'s bones 🥛',
            'avoid': 'Don\'t lie flat on your back for long periods'
          };
        case '3rd Trim':
          return {
            'badge': '🌟 Weeks 28–40',
            'hero_e': '🌟',
            'hero_t': 'The Home Stretch',
            'hero_d': 'Your body is preparing for birth. Focus on pelvic floor health, breathing, and nesting. You are almost there.',
            'mood': '⚖️ Mix of excitement and physical discomfort',
            'food': 'Dates & raspberry leaf tea (from week 36) 🫖',
            'avoid': 'Avoid heavy lifting and over-exertion'
          };
        case 'Newborn':
          return {
            'badge': '👼 Postpartum',
            'hero_e': '👼',
            'hero_t': 'The Fourth Trimester',
            'hero_d': 'Healing and bonding. Your only job is to recover and know your baby. Ask for help — you deserve it.',
            'mood': '🌊 Hormonal shifts — "baby blues" are normal',
            'food': 'Warm, easy-to-digest soups and stews 🍲',
            'avoid': 'Don\'t rush back into exercise — heal first'
          };
      }
    } else {
      switch (phase) {
        case 'Early':
          return {
            'badge': '📅 Days 1–7',
            'hero_e': '📅',
            'hero_t': 'Reset & Observe',
            'hero_d': 'New cycle, new data. Focus on clearing inflammation and preparing your uterine lining for the month ahead.',
            'mood': '🧘 Calm and focused — good for planning',
            'food': 'Anti-inflammatory: turmeric, berries, salmon 🐟',
            'avoid': 'Avoid alcohol and processed sugars'
          };
        case 'Pre-Ovul':
          return {
            'badge': '🌱 Days 8–13',
            'hero_e': '🌿',
            'hero_t': 'The Fertile Window',
            'hero_d': 'Oestrogen is rising, cervical mucus is changing. Your body is preparing to release an egg. Support your libido.',
            'mood': '🔥 Libido rising — feeling more attractive',
            'food': 'Zinc & Vitamin E: pumpkin seeds, almonds 🥜',
            'avoid': 'Avoid lubricants that aren\'t sperm-friendly'
          };
        case 'Peak':
          return {
            'badge': '🎯 Ovulation Day',
            'hero_e': '🎯',
            'hero_t': 'Ovulation Day — Act Now',
            'hero_d': 'Your LH has surged. The egg is released. This is your 12–24 hour peak window. Your body is at its most powerful.',
            'mood': '✨ Peak confidence and libido today!',
            'food': 'Antioxidants for egg quality: berries, walnuts 🫐',
            'avoid': 'Avoid hot tubs, excessive heat on the abdomen'
          };
        case 'Post-Ovul':
          return {
            'badge': '📉 Days 15–28',
            'hero_e': '🌙',
            'hero_t': 'Luteal & Implantation Window',
            'hero_d': 'Progesterone rises. If you\'re TTC, this is the implantation window (days 6–10 post-ovulation). Rest and nourish.',
            'mood': '🌊 Progesterone dip = PMS — be kind to yourself',
            'food': 'Progesterone support: vitamin B6, magnesium 🥜',
            'avoid': 'Wait until day 28 before taking a pregnancy test'
          };
      }
    }
    return {};
  }

  List<Map<String, String>> _getRitualListForPhase(String mode, String phase) {
    if (mode == 'period') {
      switch (phase) {
        case 'Menstrual':
          return [
            {'e': '🛁', 't': 'Warm Castor Oil Compress', 's': 'Place on lower abdomen to ease cramping', 'dur': '15 min'},
            {'e': '🍫', 't': 'Anti-Inflammatory Foods', 's': 'Dark chocolate, ginger tea, leafy greens', 'dur': 'All day'},
            {'e': '🧘', 't': 'Yin Yoga — Supported Child\'s Pose', 's': 'Surrender, breathe, release', 'dur': '10 min'},
            {'e': '📓', 't': 'Letting Go Journal', 's': '"What am I releasing this cycle?"', 'dur': '5 min'},
          ];
        case 'Follicular':
          return [
            {'e': '🧘', 't': 'Morning Yoga — Sun Salutation', 's': 'Energise your body as oestrogen rises', 'dur': '8 min'},
            {'e': '💆', 't': 'Gua Sha Face Massage', 's': 'Lymphatic drainage & natural glow', 'dur': '5 min'},
            {'e': '🏃', 't': 'Light Cardio or Dance', 's': 'Harness rising energy — have fun!', 'dur': '20 min'},
            {'e': '📓', 't': 'Cycle Journal Prompt', 's': '"What do I want to invite this cycle?"', 'dur': '5 min'},
          ];
        case 'Ovulatory':
          return [
            {'e': '💪', 't': 'HIIT or Strength Training', 's': 'Your pain tolerance is highest now — go for it', 'dur': '30 min'},
            {'e': '🌸', 't': 'Self-Expression Ritual', 's': 'Wear something that makes you feel powerful', 'dur': '5 min'},
            {'e': '🗣️', 't': 'Important Conversations', 's': 'Your communication is at its peak today', 'dur': 'Ongoing'},
            {'e': '🫐', 't': 'Antioxidant Smoothie', 's': 'Berries, flaxseed & maca for hormone support', 'dur': '5 min'},
          ];
        case 'Luteal':
          return [
            {'e': '🧘', 't': 'Restorative Yoga — Legs Up Wall', 's': 'Calms the nervous system, reduces bloating', 'dur': '12 min'},
            {'e': '🌿', 't': 'Seed Cycling — Sesame & Sunflower', 's': 'Day 15–28: progesterone-supporting seeds', 'dur': '2 min'},
            {'e': '📵', 't': 'Digital Sunset at 9pm', 's': 'Blue light worsens PMS — protect your sleep', 'dur': 'Nightly'},
            {'e': '🫖', 't': 'Raspberry Leaf Tea', 's': 'Traditional uterine toner & cramp support', 'dur': '5 min'},
          ];
      }
    } else if (mode == 'preg') {
      switch (phase) {
        case '1st Trim':
          return [
            {'e': '😴', 't': 'Power Nap Ritual', 's': '15-20 mins to combat first trim fatigue', 'dur': '20 min'},
            {'e': '🫚', 't': 'Ginger & Lemon Water', 's': 'Sip slowly to settle morning sickness', 'dur': 'All day'},
            {'e': '🧘', 't': 'Gentle Pelvic Tilts', 's': 'Relieve early back tension', 'dur': '5 min'},
            {'e': '📓', 't': 'First Thoughts Journal', 's': '"How I felt when I saw the positive test"', 'dur': '10 min'},
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
            {'e': '🌡️', 't': 'Confirm BBT Spike', 's': 'Temp rises 0.2–0.5°C after ovulation — log it!', 'dur': '2 min'},
            {'e': '💊', 't': 'Check OPK Result', 's': 'Look for blazing positive LH strip today', 'dur': '2 min'},
            {'e': '🏃', 't': 'Light Walk After Intimacy', 's': 'Gentle movement — no intense exercise today', 'dur': '15 min'},
            {'e': '🫐', 't': 'Antioxidant-Rich Smoothie', 's': 'Protect egg quality: berries, CoQ10, maca', 'dur': '5 min'},
          ];
        case 'Post-Ovul':
          return [
            {'e': '🌿', 't': 'Seed Cycling — Sesame & Sunflower', 's': 'Switch to Phase 2 seeds for progesterone support', 'dur': 'Daily'},
            {'e': '🧘', 't': 'Restorative Yoga', 's': 'Support progesterone with gentle, calming movement', 'dur': '12 min'},
            {'e': '🌡️', 't': 'Track BBT Stay Elevated', 's': 'If temp stays high 18+ days — take a test!', 'dur': 'Daily'},
            {'e': '🫖', 't': 'Raspberry Leaf Tea', 's': 'Uterine toner to prepare for either outcome', 'dur': '5 min'},
          ];
      }
    }
    return [];
  }
}

class RitualOverlay extends StatefulWidget {
  final List<Map<String, String>> rituals;
  final Color color;

  const RitualOverlay({super.key, required this.rituals, required this.color});

  @override
  State<RitualOverlay> createState() => _RitualOverlayState();
}

class _RitualOverlayState extends State<RitualOverlay> {
  int _currentIndex = 0;
  int _timerSec = 0;
  Timer? _timer;
  bool _timerRunning = false;
  final List<int> _completed = [];

  @override
  void initState() {
    super.initState();
    _initStep();
  }

  void _initStep() {
    final r = widget.rituals[_currentIndex];
    _timerSec = _durToSec(r['dur']!);
    _timerRunning = false;
    _timer?.cancel();
  }

  int _durToSec(String dur) {
    final m = RegExp(r'(\d+)\s*min').firstMatch(dur);
    if (m != null) return int.parse(m.group(1)!) * 60;
    return 0;
  }

  String _fmtTime(int sec) {
    if (sec <= 0) return '✓';
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
  }

  void _next() {
    if (_durToSec(widget.rituals[_currentIndex]['dur']!) > 0 && !_timerRunning && !_completed.contains(_currentIndex)) {
      _startTimer();
    } else {
      _advance();
    }
  }

  void _startTimer() {
    setState(() {
      _timerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSec > 0) {
        setState(() {
          _timerSec--;
        });
      } else {
        timer.cancel();
        _advance();
      }
    });
  }

  void _advance() {
    if (!_completed.contains(_currentIndex)) {
      setState(() {
        _completed.add(_currentIndex);
      });
    }

    if (_currentIndex < widget.rituals.length - 1) {
      setState(() {
        _currentIndex++;
        _initStep();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rituals[_currentIndex];
    final hasTimer = _durToSec(r['dur']!) > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFFEF6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(44)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: widget.color,
              ),
              Text(
                'Today\'s Ritual',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${_currentIndex + 1} of ${widget.rituals.length}',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.rituals.length,
            backgroundColor: widget.color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(widget.color),
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 40),
          Text(r['e']!, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            r['t']!,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r['s']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
          const SizedBox(height: 40),
          if (hasTimer)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: _timerSec / _durToSec(r['dur']!),
                    strokeWidth: 8,
                    backgroundColor: widget.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(widget.color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmtTime(_timerSec),
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      r['dur']!,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const Spacer(),
          Column(
            children: widget.rituals.asMap().entries.map((entry) {
              final idx = entry.key;
              final ri = entry.value;
              final isDone = _completed.contains(idx);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDone ? widget.color : Colors.white,
                        border: Border.all(color: widget.color, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ri['e']} ${ri['t']}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDone ? widget.color : AppColors.textMid,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: Text(
                hasTimer && !_timerRunning
                    ? 'Start timer ▶'
                    : _currentIndex == widget.rituals.length - 1
                        ? 'Finish session 🌸'
                        : 'Mark done & next →',
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
}


