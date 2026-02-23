import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/services/affirmation_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../providers/self_care_provider.dart';

class SelfCareScreen extends ConsumerStatefulWidget {
  const SelfCareScreen({super.key});

  @override
  ConsumerState<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends ConsumerState<SelfCareScreen> {
  int _affIdx = 0;
  String? _selectedPhase;
  String _aiAffirmation = '';
  bool _loadingAffirmation = false;

  // Fallback affirmations for when AI is unavailable
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
  void initState() {
    super.initState();
    _loadAffirmation();
  }

  Future<void> _loadAffirmation() async {
    final currentMode = ref.read(modeProvider);
    final phase = _selectedPhase ?? _getDefaultPhase(currentMode);
    
    setState(() {
      _loadingAffirmation = true;
    });

    try {
      final affirmation = await AffirmationService.getAffirmationOfTheDay(
        profile: currentMode,
        phase: phase,
      );
      
      if (mounted) {
        setState(() {
          _aiAffirmation = affirmation;
          _loadingAffirmation = false;
        });
      }
    } catch (e) {
      print('Error loading affirmation: $e');
      if (mounted) {
        setState(() {
          _loadingAffirmation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(modeProvider);
    final phasesAsync = ref.watch(phasesForModeProvider);
    
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
              phasesAsync.when(
                data: (phases) => _buildPhaseStrip(phases, color),
                loading: () => _buildPhaseStripSkeleton(),
                error: (_, __) => _buildPhaseStripFallback(currentMode, color),
              ),
              const SizedBox(height: 24),
              _buildCareHero(currentMode, color, _selectedPhase!),
              const SizedBox(height: 24),
              _buildAffirmationCard(currentMode, color),
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
              _buildRitualsSection(currentMode, color, _selectedPhase!),
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
    if (currentMode == 'period') return 'Menstrual';
    if (currentMode == 'preg') return '1st Trim';
    return 'Early';
  }

  Widget _buildPhaseStrip(List<Map<String, dynamic>> phases, Color color) {
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
              _loadAffirmation();
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
                  Text(p['emoji'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    p['label'],
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

  Widget _buildPhaseStripSkeleton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            width: 120,
            height: 36,
          );
        }),
      ),
    );
  }

  Widget _buildPhaseStripFallback(String currentMode, Color color) {
    final List<Map<String, dynamic>> phases = currentMode == 'period'
        ? [
            {'emoji': '🩸', 'label': 'Menstrual', 'key': 'Menstrual'},
            {'emoji': '🌱', 'label': 'Follicular', 'key': 'Follicular'},
            {'emoji': '✨', 'label': 'Ovulatory', 'key': 'Ovulatory'},
            {'emoji': '🌙', 'label': 'Luteal', 'key': 'Luteal'}
          ]
        : currentMode == 'preg'
            ? [
                {'emoji': '💙', 'label': '1st Trim', 'key': '1st Trim'},
                {'emoji': '🌸', 'label': '2nd Trim', 'key': '2nd Trim'},
                {'emoji': '🌟', 'label': '3rd Trim', 'key': '3rd Trim'},
                {'emoji': '👼', 'label': 'Newborn', 'key': 'Newborn'}
              ]
            : [
                {'emoji': '📅', 'label': 'Early', 'key': 'Early'},
                {'emoji': '🌱', 'label': 'Pre-Ovul', 'key': 'Pre-Ovul'},
                {'emoji': '🎯', 'label': 'Peak', 'key': 'Peak'},
                {'emoji': '📉', 'label': 'Post-Ovul', 'key': 'Post-Ovul'}
              ];

    return _buildPhaseStrip(phases, color);
  }

  Widget _buildCareHero(String currentMode, Color color, String selectedPhase) {
    final phaseDataAsync = ref.watch(phaseDataProvider(selectedPhase));

    return phaseDataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildCareHeroFallback(currentMode, color, selectedPhase);
        }
        return _buildCareHeroContent(data, color);
      },
      loading: () => _buildCareHeroSkeleton(color),
      error: (_, __) => _buildCareHeroFallback(currentMode, color, selectedPhase),
    );
  }

  Widget _buildCareHeroContent(Map<String, String> data, Color color) {
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
              data['badge'] ?? '',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(data['hero_e'] ?? '', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            data['hero_t'] ?? '',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data['hero_d'] ?? '',
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
              onPressed: () => _startRitual(_selectedPhase!),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: Text(
                "Start today's ritual",
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

  Widget _buildCareHeroSkeleton(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareHeroFallback(String currentMode, Color color, String selectedPhase) {
    final data = _getPhaseDataFallback(currentMode, selectedPhase);
    return _buildCareHeroContent(data, color);
  }

  void _startRitual(String phase) {
    final currentMode = ref.read(modeProvider);
    final ritualsAsync = ref.read(ritualListProvider(phase));
    final color = currentMode == 'preg'
        ? const Color(0xFF4A70B0)
        : currentMode == 'ovul'
            ? const Color(0xFF5A8E6A)
            : AppColors.primaryRose;

    ritualsAsync.when(
      data: (rituals) {
        if (rituals.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RitualOverlay(rituals: rituals, color: color),
          );
        }
      },
      loading: () {
        // Show loading indicator
      },
      error: (_, __) {
        // Fall back to hardcoded rituals
        final fallbackRituals = _getRitualListForPhaseFallback(currentMode, phase);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => RitualOverlay(rituals: fallbackRituals, color: color),
        );
      },
    );
  }

  Widget _buildAffirmationCard(String currentMode, Color color) {
    final displayAffirmation = _aiAffirmation.isNotEmpty
        ? _aiAffirmation
        : _allAffirmations[currentMode]?[_affIdx] ?? _allAffirmations['period']![_affIdx];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Affirmation of the day',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _affIdx = (_affIdx + 1) % (_allAffirmations[currentMode]?.length ?? 6);
                  });
                },
                child: _loadingAffirmation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh,
                        size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayAffirmation,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreatheCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('🌬️', style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breathe with Soluna',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '1 min session to center yourself',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildHabitRow(Color color) {
    return Row(
      children: [
        _buildHabitItem('💧', '8/8 glasses', 'Hydration', color),
        const SizedBox(width: 12),
        _buildHabitItem('💤', '7.5 hrs', 'Sleep', color),
      ],
    );
  }

  Widget _buildHabitItem(String emoji, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              val,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRitualsSection(String currentMode, Color color, String phase) {
    final ritualsAsync = ref.watch(ritualListProvider(phase));

    return ritualsAsync.when(
      data: (rituals) {
        if (rituals.isEmpty) {
          return _buildRitualsFallback(currentMode, color, phase);
        }
        return Column(
          children: rituals.map((r) {
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
                  Text(r['e']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['t']!,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          r['s']!,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r['dur']!,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            height: 60,
          );
        }),
      ),
      error: (_, __) => _buildRitualsFallback(currentMode, color, phase),
    );
  }

  Widget _buildRitualsFallback(String currentMode, Color color, String phase) {
    final rituals = _getRitualListForPhaseFallback(currentMode, phase);
    return Column(
      children: rituals.map((r) {
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
              Text(r['e']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['t']!,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      r['s']!,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r['dur']!,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Fallback data methods
  Map<String, String> _getPhaseDataFallback(String mode, String phase) {
    if (mode == 'period') {
      switch (phase) {
        case 'Menstrual':
          return {
            'badge': 'PHASE 1: RESTORE',
            'hero_e': '🩸',
            'hero_t': 'Winter Season',
            'hero_d':
                'Focus on rest, warmth, and gentle nourishment. Your body is clearing space for a new cycle.'
          };
        case 'Follicular':
          return {
            'badge': 'PHASE 2: RENEW',
            'hero_e': '🌱',
            'hero_t': 'Spring Season',
            'hero_d':
                'Energy is rising. Focus on planning, light movement, and fresh beginnings.'
          };
        case 'Ovulatory':
          return {
            'badge': 'PHASE 3: RADIATE',
            'hero_e': '✨',
            'hero_t': 'Summer Season',
            'hero_d':
                'Your peak energy and confidence. Perfect for socializing and high-intensity movement.'
          };
        case 'Luteal':
          return {
            'badge': 'PHASE 4: REFLECT',
            'hero_e': '🌙',
            'hero_t': 'Autumn Season',
            'hero_d':
                'Turn inward. Focus on completion, nesting, and managing PMS with care.'
          };
      }
    } else if (mode == 'preg') {
      switch (phase) {
        case '1st Trim':
          return {
            'badge': 'FOUNDATION',
            'hero_e': '💙',
            'hero_t': 'The Beginning',
            'hero_d':
                'Nurture the seed. Focus on hydration, folic acid, and plenty of rest.'
          };
        case '2nd Trim':
          return {
            'badge': 'BLOOMING',
            'hero_e': '🌸',
            'hero_t': 'The Golden Phase',
            'hero_d':
                'Feel the glow. Focus on bonding, gentle prenatal yoga, and baby prep.'
          };
        case '3rd Trim':
          return {
            'badge': 'PREPARATION',
            'hero_e': '🌟',
            'hero_t': 'The Home Stretch',
            'hero_d':
                'Prepare for arrival. Focus on nesting, birth prep, and managing discomfort.'
          };
        case 'Newborn':
          return {
            'badge': 'POSTPARTUM',
            'hero_e': '👼',
            'hero_t': 'The 4th Trimester',
            'hero_d':
                'Healing and bonding. Focus on recovery, support, and learning baby\'s cues.'
          };
      }
    } else {
      switch (phase) {
        case 'Early':
          return {
            'badge': 'PREPARATION',
            'hero_e': '📅',
            'hero_t': 'Cycle Start',
            'hero_d':
                'Laying the groundwork. Focus on baseline health and cycle tracking.'
          };
        case 'Pre-Ovul':
          return {
            'badge': 'FERTILE WINDOW',
            'hero_e': '🌱',
            'hero_t': 'Energy Rising',
            'hero_d':
                'Your body is preparing. Focus on cervical mucus signs and vitality.'
          };
        case 'Peak':
          return {
            'badge': 'OVULATION',
            'hero_e': '🎯',
            'hero_t': 'Peak Fertility',
            'hero_d':
                'The key moment. Focus on timing, BBT confirmation, and wellness.'
          };
        case 'Post-Ovul':
          return {
            'badge': 'THE WAIT',
            'hero_e': '📉',
            'hero_t': 'Implantation Window',
            'hero_d':
                'Support progesterone. Focus on calm, warmth, and mindful waiting.'
          };
      }
    }
    return {'badge': '', 'hero_e': '', 'hero_t': '', 'hero_d': ''};
  }

  List<Map<String, String>> _getRitualListForPhaseFallback(String mode, String phase) {
    if (mode == 'period') {
      switch (phase) {
        case 'Menstrual':
          return [
            {
              'e': '🍵',
              't': 'Warm Raspberry Tea',
              's': 'Soothe uterine muscles and relax',
              'dur': '5 min'
            },
            {
              'e': '🧘',
              't': 'Gentle Child\'s Pose',
              's': 'Release lower back tension',
              'dur': '10 min'
            },
            {
              'e': '📓',
              't': 'Release Journaling',
              's': 'Write down what you\'re letting go of',
              'dur': '5 min'
            },
            {
              'e': '🛌',
              't': '9 PM Digital Detox',
              's': 'Early rest to support recovery',
              'dur': 'All night'
            },
          ];
        case 'Follicular':
          return [
            {
              'e': '🏃',
              't': 'Brisk Morning Walk',
              's': 'Boost cortisol and wake up your body',
              'dur': '20 min'
            },
            {
              'e': '🥑',
              't': 'Hormone-Healthy Fats',
              's': 'Support oestrogen production',
              'dur': 'Daily'
            },
            {
              'e': '🎯',
              't': 'Set 3 Intentions',
              's': 'Plan your cycle goals now',
              'dur': '5 min'
            },
          ];
        case 'Ovulatory':
          return [
            {
              'e': '💃',
              't': 'High-Energy Movement',
              's': 'Channel your peak vitality',
              'dur': '30 min'
            },
            {
              'e': '🥗',
              't': 'Raw Veggie Fiber',
              's': 'Help your liver process oestrogen',
              'dur': 'Daily'
            },
            {
              'e': '✨',
              't': 'Social Connection',
              's': 'Call a friend or attend an event',
              'dur': 'Evening'
            },
          ];
        case 'Luteal':
          return [
            {
              'e': '🧂',
              't': 'Reduce Sodium intake',
              's': 'Minimize bloating and water retention',
              'dur': 'Daily'
            },
            {
              'e': '🧘',
              't': 'Restorative Yoga',
              's': 'Calm the nervous system',
              'dur': '15 min'
            },
            {
              'e': '🛀',
              't': 'Epsom Salt Bath',
              's': 'Magnesium for mood and cramps',
              'dur': '20 min'
            },
          ];
      }
    } else if (mode == 'preg') {
      switch (phase) {
        case '1st Trim':
          return [
            {
              'e': '💧',
              't': 'Morning Hydration',
              's': 'Small sips to manage nausea',
              'dur': 'Daily'
            },
            {
              'e': '💊',
              't': 'Prenatal Vitamin',
              's': 'Essential folic acid & iron',
              'dur': '1 min'
            },
            {
              'e': '😴',
              't': 'Mid-day Power Nap',
              's': 'Combat fatigue with 20–30 min rest',
              'dur': '30 min'
            },
          ];
        case '2nd Trim':
          return [
            {
              'e': '🧘',
              't': 'Prenatal Yoga',
              's': 'Strengthen and prepare your body',
              'dur': '20 min'
            },
            {
              'e': '🤰',
              't': 'Belly Massage',
              's': 'Soothe skin and connect with baby',
              'dur': '10 min'
            },
            {
              'e': '🍎',
              't': 'Iron-Rich Snack',
              's': 'Support blood volume increase',
              'dur': 'Daily'
            },
          ];
        case '3rd Trim':
          return [
            {
              'e': '🚶',
              't': 'Pelvic Floor Walks',
              's': 'Prepare for labor with gentle movement',
              'dur': '15 min'
            },
            {
              'e': '🌿',
              't': 'Perineal Massage',
              's': 'Tone the uterus for labor',
              'dur': '5 min'
            },
            {
              'e': '🦶',
              't': 'Foot Soak & Elevate',
              's': 'Reduce swelling and relax',
              'dur': '15 min'
            },
          ];
        case 'Newborn':
          return [
            {
              'e': '🤱',
              't': 'Skin-to-Skin Time',
              's': 'Regulate baby and boost oxytocin',
              'dur': '30 min'
            },
            {
              'e': '🍲',
              't': 'Warm, Soft Foods',
              's': 'Easy digestion for recovery',
              'dur': 'Daily'
            },
            {
              'e': '💤',
              't': 'Sleep When Baby Sleeps',
              's': 'Prioritize rest over chores',
              'dur': 'Daily'
            },
          ];
      }
    } else {
      switch (phase) {
        case 'Early':
          return [
            {
              'e': '🧘',
              't': 'Grounding Yoga',
              's': 'Center yourself',
              'dur': '15 min'
            },
            {
              'e': '💧',
              't': 'Hydration Ritual',
              's': 'Start hydrating well',
              'dur': 'All day'
            },
            {
              'e': '📓',
              't': 'Fertility Journal',
              's': 'Note your observations',
              'dur': '5 min'
            },
          ];
        case 'Pre-Ovul':
          return [
            {
              'e': '🧘',
              't': 'Core & Hip Yoga Flow',
              's': 'Boost blood flow to reproductive organs',
              'dur': '10 min'
            },
            {
              'e': '🌿',
              't': 'Seed Cycling — Flax & Pumpkin',
              's': 'Day 1–14: oestrogen-supporting seeds',
              'dur': '2 min'
            },
            {
              'e': '🌡️',
              't': 'BBT Journaling',
              's': 'Log your temp trend and cervical signs',
              'dur': '3 min'
            },
            {
              'e': '💧',
              't': 'Hydration Ritual',
              's': 'Cervical mucus loves water — drink up!',
              'dur': 'All day'
            },
          ];
        case 'Peak':
          return [
            {
              'e': '🌡️',
              't': 'Confirm BBT Spike',
              's': 'Temp rises 0.2–0.5°C after ovulation — log it!',
              'dur': '2 min'
            },
            {
              'e': '💊',
              't': 'Check OPK Result',
              's': 'Look for blazing positive LH strip today',
              'dur': '2 min'
            },
            {
              'e': '🏃',
              't': 'Light Walk After Intimacy',
              's': 'Gentle movement — no intense exercise today',
              'dur': '15 min'
            },
            {
              'e': '🫐',
              't': 'Antioxidant-Rich Smoothie',
              's': 'Protect egg quality: berries, CoQ10, maca',
              'dur': '5 min'
            },
          ];
        case 'Post-Ovul':
          return [
            {
              'e': '🌿',
              't': 'Seed Cycling — Sesame & Sunflower',
              's': 'Switch to Phase 2 seeds for progesterone support',
              'dur': 'Daily'
            },
            {
              'e': '🧘',
              't': 'Restorative Yoga',
              's': 'Support progesterone with gentle, calming movement',
              'dur': '12 min'
            },
            {
              'e': '🌡️',
              't': 'Track BBT Stay Elevated',
              's': 'If temp stays high 18+ days — take a test!',
              'dur': 'Daily'
            },
            {
              'e': '🫖',
              't': 'Raspberry Leaf Tea',
              's': 'Uterine toner to prepare for either outcome',
              'dur': '5 min'
            },
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
    if (_durToSec(widget.rituals[_currentIndex]['dur']!) > 0 &&
        !_timerRunning &&
        !_completed.contains(_currentIndex)) {
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
    final bgColor = widget.color == const Color(0xFF4A70B0)
        ? const Color(0xFFF4F7FF)
        : widget.color == const Color(0xFF5A8E6A)
            ? const Color(0xFFF2FBF5)
            : const Color(0xFFFEF6F0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
                Text(
                  'Today\'s Ritual',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} of ${widget.rituals.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentIndex + 1) / widget.rituals.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(r['e']!, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    r['t']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r['s']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (hasTimer)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _timerSec / _durToSec(r['dur']!),
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                            backgroundColor: widget.color.withOpacity(0.1),
                          ),
                        ),
                        Text(
                          _fmtTime(_timerSec),
                          style: GoogleFonts.nunito(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: Text(
                  _timerRunning ? 'Running...' : 'Next',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
