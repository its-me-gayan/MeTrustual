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
import 'ritual_overlay.dart';

class SelfCareScreen extends ConsumerStatefulWidget {
  const SelfCareScreen({super.key});

  @override
  ConsumerState<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends ConsumerState<SelfCareScreen> {
  String? _selectedPhase;
  String _aiAffirmation = '';
  bool _loadingAffirmation = false;

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
                data: (phases) => phases.isEmpty
                    ? _buildNoDataChip('No phases available')
                    : _buildPhaseStrip(phases, color),
                loading: () => _buildPhaseStripSkeleton(),
                error: (_, __) => _buildNoDataChip('Could not load phases'),
              ),
              const SizedBox(height: 24),
              _buildCareHero(currentMode, color, _selectedPhase!),
              const SizedBox(height: 24),
              _buildAffirmationCard(color),
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
              _buildRitualsSection(color, _selectedPhase!),
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

  // ── Generic "no data" widgets ──────────────────────────────────────────────

  Widget _buildNoDataChip(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Text(
        message,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase strip ────────────────────────────────────────────────────────────

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

  // ── Care hero ──────────────────────────────────────────────────────────────

  Widget _buildCareHero(String currentMode, Color color, String selectedPhase) {
    final phaseDataAsync = ref.watch(phaseDataProvider(selectedPhase));

    return phaseDataAsync.when(
      data: (data) {
        if (data.isEmpty)
          return _buildNoDataCard('No data available for this phase');
        return _buildCareHeroContent(data, color);
      },
      loading: () => _buildCareHeroSkeleton(),
      error: (_, __) => _buildNoDataCard('Could not load phase data'),
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

  Widget _buildCareHeroSkeleton() {
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
            // Change to:
            builder: (context) => RitualOverlay(
              rituals: rituals,
              color: color,
              phase: phase, // ← add this
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No rituals available for this phase')),
          );
        }
      },
      loading: () {},
      error: (_, __) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load rituals')),
        );
      },
    );
  }

  // ── Affirmation card ───────────────────────────────────────────────────────

  Widget _buildAffirmationCard(Color color) {
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
                onTap: _loadAffirmation,
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
          _loadingAffirmation
              ? Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              : Text(
                  _aiAffirmation.isNotEmpty
                      ? _aiAffirmation
                      : 'No affirmation available',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: _aiAffirmation.isNotEmpty ? 18 : 14,
                    fontWeight: FontWeight.w800,
                    color: _aiAffirmation.isNotEmpty
                        ? AppColors.textDark
                        : AppColors.textMuted,
                    fontStyle: _aiAffirmation.isNotEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
        ],
      ),
    );
  }

  // ── Breathe card ───────────────────────────────────────────────────────────

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
            child: const Center(
              child: Text('🌬️', style: TextStyle(fontSize: 24)),
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

  // ── Habits ─────────────────────────────────────────────────────────────────

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

  // ── Rituals section ────────────────────────────────────────────────────────

  Widget _buildRitualsSection(Color color, String phase) {
    final ritualsAsync = ref.watch(ritualListProvider(phase));

    return ritualsAsync.when(
      data: (rituals) {
        if (rituals.isEmpty) {
          return _buildNoDataCard('No rituals available for this phase');
        }
        return Column(
          children: rituals.map((r) => _buildRitualTile(r, color)).toList(),
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
      error: (_, __) => _buildNoDataCard('Could not load rituals'),
    );
  }

  Widget _buildRitualTile(Map<String, String> r, Color color) {
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
  }
}

// ── Ritual overlay (unchanged logic, no fallback data) ─────────────────────
