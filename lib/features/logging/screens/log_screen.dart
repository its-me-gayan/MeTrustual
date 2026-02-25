import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/premium_gate.dart';

class LogScreen extends ConsumerStatefulWidget {
  final DateTime? date;
  const LogScreen({super.key, this.date});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  late final DateTime _selectedDate;
  bool _isSaving = false;

  // ── Existing log state ────────────────────────────────
  bool _isExistingLog = false;
  DateTime? _lastUpdatedAt;
  bool _isLoadingExisting = true;

  // ── Period Mode State ─────────────────────────────────
  String? selectedFlow;
  String? selectedMoodPeriod;
  List<String> selectedSymptomsPeriod = [];
  int waterGlasses = 6;
  int sleepHours = 7;
  final TextEditingController _periodNoteCtrl = TextEditingController();

  // ── Pregnancy Mode State ──────────────────────────────
  int kicks = 0;
  String? selectedMoodPreg;
  List<String> selectedSymptomsPreg = [];
  int waterGlassesPreg = 8;
  int weightKg = 64;
  final TextEditingController _pregApptNoteCtrl = TextEditingController();

  // ── Ovulation Mode State ──────────────────────────────
  final TextEditingController _bbtCtrl = TextEditingController(text: '36.72');
  String? selectedCervicalMucus;
  String? selectedOpkResult;
  String? selectedMoodOvul;
  List<String> selectedSymptomsOvul = [];
  final TextEditingController _ovulNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date ?? DateTime.now();
    // Defer until after first frame so ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingLog());
  }

  @override
  void dispose() {
    _periodNoteCtrl.dispose();
    _pregApptNoteCtrl.dispose();
    _bbtCtrl.dispose();
    _ovulNoteCtrl.dispose();
    super.dispose();
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _todayLabel =>
      DateFormat('EEEE · MMM d, yyyy').format(_selectedDate);

  // ── Load existing log from Firestore ─────────────────
  Future<void> _loadExistingLog() async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoadingExisting = false);
      return;
    }
    final mode = ref.read(modeProvider);
    final firestore = ref.read(firestoreProvider);

    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('logs')
          .doc(mode)
          .collection('entries')
          .doc(_todayKey)
          .get();

      if (doc.exists && mounted) {
        final d = doc.data()!;

        // Resolve savedAt timestamp
        DateTime? savedAt;
        if (d['savedAt'] is Timestamp) {
          savedAt = (d['savedAt'] as Timestamp).toDate();
        }

        // Pre-fill based on mode
        if (mode == 'period') {
          selectedFlow = d['flow'] as String?;
          selectedMoodPeriod = d['mood'] as String?;
          selectedSymptomsPeriod =
              List<String>.from(d['symptoms'] as List? ?? []);
          waterGlasses = (d['water'] as num?)?.toInt() ?? 6;
          sleepHours = (d['sleep'] as num?)?.toInt() ?? 7;
          _periodNoteCtrl.text = d['note'] as String? ?? '';
        } else if (mode == 'preg') {
          kicks = (d['kicks'] as num?)?.toInt() ?? 0;
          selectedMoodPreg = d['mood'] as String?;
          selectedSymptomsPreg =
              List<String>.from(d['symptoms'] as List? ?? []);
          waterGlassesPreg = (d['water'] as num?)?.toInt() ?? 8;
          weightKg = (d['weight'] as num?)?.toInt() ?? 64;
          _pregApptNoteCtrl.text = d['appointmentNote'] as String? ?? '';
        } else if (mode == 'ovul') {
          final bbt = d['bbt'];
          if (bbt != null) _bbtCtrl.text = bbt.toString();
          selectedCervicalMucus = d['mucus'] as String?;
          selectedOpkResult = d['opk'] as String?;
          selectedMoodOvul = d['mood'] as String?;
          selectedSymptomsOvul =
              List<String>.from(d['symptoms'] as List? ?? []);
          _ovulNoteCtrl.text = d['note'] as String? ?? '';
        }

        setState(() {
          _isExistingLog = true;
          _lastUpdatedAt = savedAt;
          _isLoadingExisting = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingExisting = false);
      }
    } catch (_) {
      // Silently fail — user can still log fresh
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  // ── Save to Firebase ──────────────────────────────────
  Future<void> _save() async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    final mode = ref.read(modeProvider);
    final firestore = ref.read(firestoreProvider);

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> data = {
        'date': _todayKey,
        'mode': mode,
        'savedAt': FieldValue.serverTimestamp(),
      };

      if (mode == 'period') {
        data['flow'] = selectedFlow ?? '';
        data['mood'] = selectedMoodPeriod ?? '';
        data['symptoms'] = selectedSymptomsPeriod;
        data['water'] = waterGlasses;
        data['sleep'] = sleepHours;
        data['note'] = _periodNoteCtrl.text.trim();
      } else if (mode == 'preg') {
        data['kicks'] = kicks;
        data['mood'] = selectedMoodPreg ?? '';
        data['symptoms'] = selectedSymptomsPreg;
        data['water'] = waterGlassesPreg;
        data['weight'] = weightKg;
        data['appointmentNote'] = _pregApptNoteCtrl.text.trim();
      } else if (mode == 'ovul') {
        data['bbt'] = double.tryParse(_bbtCtrl.text) ?? 0.0;
        data['mucus'] = selectedCervicalMucus ?? '';
        data['opk'] = selectedOpkResult ?? '';
        data['mood'] = selectedMoodOvul ?? '';
        data['symptoms'] = selectedSymptomsOvul;
        data['note'] = _ovulNoteCtrl.text.trim();
      }

      await firestore
          .collection('users')
          .doc(uid)
          .collection('logs')
          .doc(mode)
          .collection('entries')
          .doc(_todayKey)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        NotificationService.showSuccess(
          context,
          _isExistingLog ? 'Log updated! 🌸' : 'Log saved! 🌸',
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Formatted last-updated label ─────────────────────
  String get _lastUpdatedLabel {
    if (_lastUpdatedAt == null) return 'Last updated today';
    final time = DateFormat('h:mm a').format(_lastUpdatedAt!.toLocal());
    return 'Last updated · $time';
  }

  // ── Button label ──────────────────────────────────────
  String _getButtonLabel(String mode) {
    final verb = _isExistingLog ? "Update" : "Save";
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayLabel = isToday ? "today's" : "this day's";

    switch (mode) {
      case 'period':
        return "$verb $dayLabel log ✓";
      case 'preg':
        return "$verb $dayLabel log 💙";
      case 'ovul':
        return "$verb $dayLabel log 🌿";
      default:
        return "$verb $dayLabel log";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(modeProvider);
    final color = _getAccentColor(currentMode);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: _isLoadingExisting
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryRose,
                  strokeWidth: 2.5,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20),
                          color: AppColors.textDark,
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                        ),
                        Text(
                          _getPageTitle(currentMode),
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),

                    // ── Date & last-updated ─────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _todayLabel,
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (_isExistingLog) ...[
                            const SizedBox(height: 4),
                            _buildLastUpdatedBadge(color),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildModeSpecificLogContent(currentMode),
                    const SizedBox(height: 20),
                    _buildSaveButton(currentMode, color),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Last updated badge ────────────────────────────────
  Widget _buildLastUpdatedBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 10, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            _lastUpdatedLabel,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  PERIOD LOG
  // ─────────────────────────────────────────────────────
  Widget _buildPeriodLogContent() {
    const color = AppColors.primaryRose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Flow today?'),
        _buildFlowSelection(),
        _sectionTitle('Mood?'),
        _buildMoodSelection('period'),
        _sectionTitle('Physical symptoms?'),
        _buildChipsMulti(
          [
            '🌀 Cramps',
            '🤕 Headache',
            '😴 Fatigue',
            '🤢 Nausea',
            '🌊 Bloating',
            '💆 Back Pain',
            '🍫 Cravings',
            '😤 Mood Swings',
            '🌡️ Breast Tenderness',
            '✚ More'
          ],
          selectedSymptomsPeriod,
          (chip) => setState(() => selectedSymptomsPeriod.contains(chip)
              ? selectedSymptomsPeriod.remove(chip)
              : selectedSymptomsPeriod.add(chip)),
          color,
        ),
        _sectionTitle('Wellness'),
        _buildLogStepperRow(
          '💧 Water (glasses)',
          waterGlasses,
          0,
          15,
          (v) => setState(() => waterGlasses = v),
          '🌙 Sleep (hrs)',
          sleepHours,
          0,
          12,
          (v) => setState(() => sleepHours = v),
          color,
        ),
        // ── PREMIUM: Cycle phase tip ────────────────────
        _sectionTitle('Phase tip ✨'),
        PremiumGate(
          message: 'Unlock Cycle Phase Tips',
          child: _buildPhaseTipCard(color),
        ),
        _sectionTitle('Note to self 🌷'),
        _buildNoteField(
            'Just for you — how are you really feeling?', _periodNoteCtrl),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  PREGNANCY LOG
  // ─────────────────────────────────────────────────────
  Widget _buildPregnancyLogContent() {
    const color = Color(0xFF4A70B0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── PREMIUM: Kick Counter ───────────────────────
        _sectionTitle('Kick Counter 👶'),
        PremiumGate(
          message: 'Unlock Kick Counter',
          child: _buildKickCounter(),
        ),
        _sectionTitle('How are you feeling?'),
        _buildMoodSelection('preg'),
        _sectionTitle('Symptoms today?'),
        _buildChipsMulti(
          [
            '🤢 Nausea',
            '🔥 Heartburn',
            '😴 Fatigue',
            '💆 Back Pain',
            '🦵 Leg Cramps',
            '🌊 Swelling',
            '😰 Anxiety',
            '😴 Insomnia',
            '🤯 Brain Fog',
            '✨ Feeling great!'
          ],
          selectedSymptomsPreg,
          (chip) => setState(() => selectedSymptomsPreg.contains(chip)
              ? selectedSymptomsPreg.remove(chip)
              : selectedSymptomsPreg.add(chip)),
          color,
        ),
        _sectionTitle('Wellness'),
        _buildLogStepperRow(
          '💧 Water (glasses)',
          waterGlassesPreg,
          0,
          15,
          (v) => setState(() => waterGlassesPreg = v),
          '⚖️ Weight (kg)',
          weightKg,
          40,
          150,
          (v) => setState(() => weightKg = v),
          color,
        ),
        // ── PREMIUM: Baby development ───────────────────
        _sectionTitle('Baby this week 🌱'),
        PremiumGate(
          message: 'Unlock Weekly Baby Updates',
          child: _buildBabyDevelopmentCard(),
        ),
        _sectionTitle('Appointment notes 🩺'),
        _buildNoteField('Notes from your last visit, questions for next time…',
            _pregApptNoteCtrl),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  OVULATION LOG
  // ─────────────────────────────────────────────────────
  Widget _buildOvulationLogContent() {
    const color = Color(0xFF5A8E6A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── PREMIUM: BBT Input ──────────────────────────
        _sectionTitle('Basal Body Temperature 🌡️'),
        PremiumGate(
          message: 'Unlock BBT Logging',
          child: _buildBBTInput(),
        ),
        _sectionTitle('Cervical mucus?'),
        _buildChipsSingle(
          [
            '🏜️ Dry / None',
            '🍬 Sticky',
            '🥛 Creamy',
            '💧 Watery',
            '🥚 Egg White (peak!)'
          ],
          selectedCervicalMucus,
          (chip) => setState(() => selectedCervicalMucus = chip),
          color,
        ),
        _sectionTitle('OPK Test result?'),
        _buildChipsSingle(
          ['⬜ Negative', '🟡 Low', '🟠 High', '🎯 Peak!', '⏭️ Didn\'t test'],
          selectedOpkResult,
          (chip) => setState(() => selectedOpkResult = chip),
          color,
        ),
        _sectionTitle('Mood & energy?'),
        _buildMoodSelection('ovul'),
        _sectionTitle('Other symptoms?'),
        _buildChipsMulti(
          [
            '🩸 Mid-cycle spotting',
            '💫 Ovulation pain (Mittelschmerz)',
            '🌿 High libido',
            '🌡️ Feeling warm'
          ],
          selectedSymptomsOvul,
          (chip) => setState(() => selectedSymptomsOvul.contains(chip)
              ? selectedSymptomsOvul.remove(chip)
              : selectedSymptomsOvul.add(chip)),
          color,
        ),
        // ── PREMIUM: Fertility insight ──────────────────
        _sectionTitle('Fertility insight 🎯'),
        PremiumGate(
          message: 'Unlock Fertile Window Analysis',
          child: _buildFertilityInsightCard(),
        ),
        _sectionTitle('Note 🌷'),
        _buildNoteField('Anything else worth noting today?', _ovulNoteCtrl),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  PREMIUM CONTENT WIDGETS
  // ─────────────────────────────────────────────────────

  Widget _buildPhaseTipCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🌿', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('Fertile Window — Day 10–16',
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Your energy peaks now. Great time for exercise, social plans, and creative work. Oestrogen is high — you may feel more confident.',
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid,
                height: 1.5),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [
            _tipPill('🥦 Iron-rich foods', color),
            _tipPill('💧 Stay hydrated', color),
            _tipPill('🏃 Move your body', color),
          ]),
        ],
      ),
    );
  }

  Widget _tipPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildBabyDevelopmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F4FF), Color(0xFFE8EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8D8F4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEK 24 · WHAT\'S HAPPENING',
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7090C0),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌽', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Baby is the size of a corn cob!',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(
                      'About 30cm and 600g. Baby\'s face is fully formed and practising breathing movements. Brain growing rapidly 💙',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF4A70B0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Baby weight: ~600g  •  Length: ~30cm',
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A70B0))),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilityInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FAF4), Color(0xFFE8F5EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB0D8C0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🟢 Fertile Window — Day 10 to 16',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5A8E6A))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 10,
              backgroundColor: Color(0xFFE8F5EE),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A8E6A)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day 10',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFA0C8B0))),
              Text('Peak (Day 14)',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5A8E6A))),
              Text('Day 16',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFA0C8B0))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'BBT rise + egg-white mucus + high OPK confirms peak fertility. Your pattern is very consistent — 89% prediction accuracy 🌿',
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SHARED UI HELPERS
  // ─────────────────────────────────────────────────────

  Widget _buildModeSpecificLogContent(String currentMode) {
    switch (currentMode) {
      case 'period':
        return _buildPeriodLogContent();
      case 'preg':
        return _buildPregnancyLogContent();
      case 'ovul':
        return _buildOvulationLogContent();
      default:
        return const SizedBox();
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFC0A0A8),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFlowSelection() {
    final flows = [
      {'icon': '🔴', 'label': 'Heavy', 'value': 'heavy'},
      {'icon': '🟠', 'label': 'Medium', 'value': 'medium'},
      {'icon': '🟡', 'label': 'Light', 'value': 'light'},
      {'icon': '🤍', 'label': 'None', 'value': 'none'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: flows.map((flow) {
        final isSelected = selectedFlow == flow['value'];
        return GestureDetector(
          onTap: () => setState(() => selectedFlow = flow['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryRose.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryRose
                    : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppColors.primaryRose.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Column(children: [
              Text(flow['icon']!, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(flow['label']!,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.primaryRose
                          : AppColors.textMuted)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodSelection(String mode) {
    final moods = ['😔', '😐', '🙂', '😊', '🥰'];
    final color = _getAccentColor(mode);
    String? current;
    switch (mode) {
      case 'period':
        current = selectedMoodPeriod;
        break;
      case 'preg':
        current = selectedMoodPreg;
        break;
      case 'ovul':
        current = selectedMoodOvul;
        break;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: moods.map((mood) {
        final isSelected = current == mood;
        return GestureDetector(
          onTap: () => setState(() {
            switch (mode) {
              case 'period':
                selectedMoodPeriod = mood;
                break;
              case 'preg':
                selectedMoodPreg = mood;
                break;
              case 'ovul':
                selectedMoodOvul = mood;
                break;
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? color : const Color(0xFFFCE8E4),
                  width: 1.5),
            ),
            child: Text(mood, style: TextStyle(fontSize: isSelected ? 28 : 24)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKickCounter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F4FF), Color(0xFFE8EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC0D0F0), width: 1.5),
      ),
      child: Column(children: [
        Text('👶 KICK COUNTER — TODAY',
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7090C0),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text('$kicks',
              key: ValueKey(kicks),
              style: GoogleFonts.nunito(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4A70B0),
                  height: 1)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => kicks++),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF4A70B0).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ],
            ),
            child:
                const Center(child: Text('👶', style: TextStyle(fontSize: 30))),
          ),
        ),
        const SizedBox(height: 12),
        Text('Tap when you feel baby move — aim for 10 kicks in 2 hours',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7090C0))),
      ]),
    );
  }

  Widget _buildBBTInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF5A8E6A).withOpacity(0.3), width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🌡️ BASAL BODY TEMPERATURE',
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5A8E6A),
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(
          controller: _bbtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF5A8E6A)),
          decoration: InputDecoration(
            hintText: '36.70',
            hintStyle: GoogleFonts.nunito(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5A8E6A).withOpacity(0.3)),
            border: InputBorder.none,
          ),
        ),
        Text('°C — taken immediately on waking, before getting up',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA0C0B0))),
      ]),
    );
  }

  Widget _buildChipsMulti(List<String> chips, List<String> selected,
      Function(String) onToggle, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        final isSelected = selected.contains(chip);
        return GestureDetector(
          onTap: () => onToggle(chip),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.6)
                      : const Color(0xFFFCE8E4),
                  width: 1.5),
            ),
            child: Text(chip,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : const Color(0xFFC0A0A8))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipsSingle(List<String> chips, String? selected,
      Function(String) onSelect, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        final isSelected = selected == chip;
        return GestureDetector(
          onTap: () => onSelect(chip),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.6)
                      : const Color(0xFFFCE8E4),
                  width: 1.5),
            ),
            child: Text(chip,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : const Color(0xFFC0A0A8))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogStepperRow(
    String l1,
    int v1,
    int min1,
    int max1,
    Function(int) onC1,
    String l2,
    int v2,
    int min2,
    int max2,
    Function(int) onC2,
    Color color,
  ) {
    return Row(children: [
      Expanded(child: _buildLogStepper(l1, v1, min1, max1, onC1, color)),
      const SizedBox(width: 12),
      Expanded(child: _buildLogStepper(l2, v2, min2, max2, onC2, color)),
    ]);
  }

  Widget _buildLogStepper(String label, int value, int min, int max,
      Function(int) onChanged, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
      ),
      child: Column(children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stepBtn(Icons.remove, color, () {
              if (value > min) onChanged(value - 1);
            }),
            Text('$value',
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            _stepBtn(Icons.add, color, () {
              if (value < max) onChanged(value + 1);
            }),
          ],
        ),
      ]),
    );
  }

  Widget _stepBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildNoteField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A3838)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFDDBEC0)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFCE8E4), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFCE8E4), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF0B0B8), width: 1.5)),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _buildSaveButton(String mode, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: mode == 'period'
              ? [const Color(0xFFF09090), const Color(0xFFD97B8A)]
              : mode == 'preg'
                  ? [const Color(0xFF7AA0E0), const Color(0xFF4A70B0)]
                  : [const Color(0xFF78C890), const Color(0xFF5A8E6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.35),
              offset: const Offset(0, 6),
              blurRadius: 18)
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(
                _getButtonLabel(mode),
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
      ),
    );
  }

  String _getPageTitle(String mode) {
    switch (mode) {
      case 'period':
        return 'How are you? 🌸';
      case 'preg':
        return 'Daily Log 💙';
      case 'ovul':
        return 'Daily Log 🌿';
      default:
        return 'Daily Log';
    }
  }

  Color _getAccentColor(String mode) {
    switch (mode) {
      case 'preg':
        return const Color(0xFF4A70B0);
      case 'ovul':
        return const Color(0xFF5A8E6A);
      default:
        return AppColors.primaryRose;
    }
  }
}
