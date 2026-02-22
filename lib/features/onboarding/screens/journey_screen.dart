import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../providers/journey_provider.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  final String mode;
  const JourneyScreen({super.key, required this.mode});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  int currentStep = 0;
  final Map<String, dynamic> journeyData = {};
  bool _isLoading = false;
  bool _stepsLoaded = false;

  late List<Map<String, dynamic>> steps;
  late final Color accentColor;
  late final LinearGradient progressGradient;

  @override
  void initState() {
    super.initState();
    accentColor = _getModeColor(widget.mode);
    progressGradient = _getModeGradient(widget.mode);
    _loadJourneyStepsAndData();
  }

  Future<void> _loadJourneyStepsAndData() async {
    setState(() => _isLoading = true);
    try {
      // Try to load combined data (static steps + user selections)
      final combinedData = await ref.read(combinedJourneyDataProvider(widget.mode).future);
      final stepsAsyncValue = combinedData['steps'] as List<Map<String, dynamic>>;
      final userSelections = combinedData['userSelections'] as Map<String, dynamic>;
      
      setState(() {
        steps = stepsAsyncValue;
        journeyData.addAll(userSelections);
        _stepsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading combined journey data: $e');
      try {
        // Fallback: load just the steps
        final stepsAsyncValue = await ref.read(journeyStepsProvider(widget.mode).future);
        setState(() {
          steps = stepsAsyncValue;
          _stepsLoaded = true;
        });
        await _loadExistingData();
      } catch (e2) {
        debugPrint('Error loading journey steps fallback: $e2');
        setState(() {
          steps = _getHardcodedJourneySteps(widget.mode);
          _stepsLoaded = true;
        });
        await _loadExistingData();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(firebaseAuthProvider);
      final firestore = ref.read(firestoreProvider);
      final uid = auth.currentUser?.uid;

      if (uid != null) {
        final doc = await firestore
            .collection('users')
            .doc(uid)
            .collection('journey')
            .doc(widget.mode)
            .get();
        if (doc.exists) {
          debugPrint(doc.data().toString());
          debugPrint(
              'Existing journey data found for user $uid and mode ${widget.mode}');
          setState(() {
            journeyData.addAll(doc.data()!);
          });
        } else {
          debugPrint(
              'No existing journey data found for user $uid and mode ${widget.mode}');
        }
      }
    } catch (e) {
      debugPrint('Error loading journey data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'preg':
        return const Color(0xFF4A70B0);
      case 'ovul':
        return const Color(0xFF5A8E6A);
      default:
        return const Color(0xFFD97B8A);
    }
  }

  LinearGradient _getModeGradient(String mode) {
    switch (mode) {
      case 'preg':
        return const LinearGradient(
          colors: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ovul':
        return const LinearGradient(
          colors: [Color(0xFF78C890), Color(0xFF5A8E6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFF09090), Color(0xFFD97B8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Future<void> _saveData() async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firestoreProvider);
    final uid = auth.currentUser?.uid;

    if (uid != null) {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('journey')
          .doc(widget.mode)
          .set(journeyData, SetOptions(merge: true));
    }
  }

  Future<void> _nextStep() async {
    if (!_stepsLoaded) return;

    final step = steps[currentStep];
    final key = step['key'];
    final isRequired = step['required'] == true;
    final value = journeyData[key];

    if (isRequired && (value == null || (value is List && value.isEmpty))) {
      NotificationService.showError(
          context, 'Please make a selection to continue');
      return;
    }

    await _saveData();
    if (currentStep < steps.length - 1) {
      setState(() => currentStep++);
    } else {
      await ref.read(modeProvider.notifier).setMode(widget.mode);
      await ref.read(modeProvider.notifier).completeJourney();

      final auth = ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;

      if (mounted) {
        context.go('/biometric-setup/$uid');
      }
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    } else {
      context.go('/mode-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_stepsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final step = steps[currentStep];
    final progress = (currentStep + 1) / steps.length;
    final isSingleChoice =
        step['type'] == 'chips-big-single' || step['type'] == 'chips-single';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F5), Color(0xFFFEF0F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _prevStep,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFCE8E4), width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 16, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE8E4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: progressGradient,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'STEP ${currentStep + 1} OF ${steps.length}',
                            style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFD0B0B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(step['icon'],
                          style: GoogleFonts.nunito(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        step['q'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['sub'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB09090),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildStepInput(step),
                      if (step['warn'] != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    const Color(0xFFF0B0B8).withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Color(0xFFD97B8A), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step['warn'],
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD97B8A),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (step['skip'] != null)
                      TextButton(
                        onPressed: _nextStep,
                        child: Text(
                          step['skip'],
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD0B0B8),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (!isSingleChoice)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: accentColor.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            currentStep == steps.length - 1
                                ? "Done! Let's go →"
                                : 'Continue →',
                            style: GoogleFonts.nunito(
                                fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepInput(Map<String, dynamic> step) {
    final String key = step['key'];
    final dynamic currentValue = journeyData[key];

    switch (step['type']) {
      case 'chips-big-single':
      case 'chips-single':
        final List opts = step['opts'];
        return Column(
          children: opts.map((opt) {
            final isSpecial = opt['special'] == true;
            final isSelected = currentValue == opt['v'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  if (opt['v'] == 'switch') {
                    context.go('/mode-selection');
                  } else {
                    setState(() {
                      journeyData[key] = opt['v'];
                    });
                    _nextStep();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? accentColor.withOpacity(0.5)
                          : (isSpecial
                              ? const Color(0xFFF0B0B8).withOpacity(0.5)
                              : const Color(0xFFFCE8E4)),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(opt['e'], style: GoogleFonts.nunito(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt['l'],
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isSpecial
                                ? const Color(0xFFD97B8A)
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.chevron_right,
                        color: isSelected
                            ? accentColor.withOpacity(0.5)
                            : (isSpecial
                                ? const Color(0xFFD97B8A).withOpacity(0.5)
                                : const Color(0xFFD0B0B8)),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      case 'chips-multi':
        final List opts = step['opts'];
        final List<String> selected = List<String>.from(currentValue ?? []);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: opts.map((opt) {
            final String label = opt['l'];
            final isSelected = selected.contains(label);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(label);
                  } else {
                    selected.add(label);
                  }
                  journeyData[key] = selected;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? accentColor.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? accentColor.withOpacity(0.5)
                        : const Color(0xFFFCE8E4),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${opt['e']} $label',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? accentColor : AppColors.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      case 'date':
      case 'due-date':
        final DateTime? date =
            currentValue != null ? (currentValue as Timestamp).toDate() : null;
        return GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() {
                journeyData[key] = Timestamp.fromDate(picked);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFCE8E4), width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: accentColor, size: 22),
                const SizedBox(width: 14),
                Text(
                  date != null
                      ? "${date.day}/${date.month}/${date.year}"
                      : 'Select Date',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMid,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFD0B0B8)),
              ],
            ),
          ),
        );
      case 'stepper':
        final int val = currentValue ?? step['def'];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFCE8E4), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['unit'],
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB09090),
                    ),
                  ),
                  Text(
                    '$val',
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildStepBtn(Icons.remove, () {
                    if (val > step['min']) {
                      setState(() => journeyData[key] = val - 1);
                    }
                  }),
                  const SizedBox(width: 10),
                  _buildStepBtn(Icons.add, () {
                    if (val < step['max']) {
                      setState(() => journeyData[key] = val + 1);
                    }
                  }),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: widget.mode == 'preg'
              ? const Color(0xFFDDE8F8)
              : widget.mode == 'ovul'
                  ? const Color(0xFFD0E8D8)
                  : const Color(0xFFFCE8E4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
    );
  }
}
