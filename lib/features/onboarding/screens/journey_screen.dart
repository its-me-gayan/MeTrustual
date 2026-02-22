import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoadingData = false;

  late final Color accentColor;
  late final LinearGradient progressGradient;

  @override
  void initState() {
    super.initState();
    accentColor = _getModeColor(widget.mode);
    progressGradient = _getModeGradient(widget.mode);
    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    setState(() => _isLoadingData = true);
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
          setState(() {
            journeyData.addAll(doc.data()!);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading existing journey data: $e');
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'preg':
        return const Color(0xFF4A70B0);
      case 'ovul':
        return const Color(0xFF5A8E6A);
      default:
        return AppColors.primaryRose;
    }
  }

  LinearGradient _getModeGradient(String mode) {
    switch (mode) {
      case 'preg':
        return const LinearGradient(
            colors: [Color(0xFF7AA0E0), Color(0xFF4A70B0)]);
      case 'ovul':
        return const LinearGradient(
            colors: [Color(0xFF78C890), Color(0xFF5A8E6A)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFFF09090), AppColors.primaryRose]);
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

  Future<void> _nextStep(List<Map<String, dynamic>> steps) async {
    final step = steps[currentStep];
    final key = step['key'];
    final isRequired = step['required'] == true;
    final value = journeyData[key];

    if (isRequired && (value == null || (value is List && value.isEmpty))) {
      NotificationService.showError(context, 'Please make a selection to continue');
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
    return Scaffold(
      body: ref.watch(journeyStepsProvider(widget.mode)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          debugPrint('Error loading journey steps: $error\n$stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load journey steps'),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/mode-selection'),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        },
        data: (steps) {
          if (steps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('No journey steps found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/mode-selection'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final step = steps[currentStep];
          final progress = (currentStep + 1) / steps.length;
          final isSingleChoice = step['type'] == 'chips-big-single' || step['type'] == 'chips-single';

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: progressGradient),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _prevStep,
                              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                            ),
                            Text(
                              'STEP ${currentStep + 1} OF ${steps.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              step['icon'],
                              style: const TextStyle(fontSize: 56),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              step['q'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step['sub'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                            if (step['warn'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    step['warn'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                            _buildStepInput(step),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (step['skip'] != null)
                          TextButton(
                            onPressed: () => _nextStep(steps),
                            child: Text(
                              step['skip'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD0B0B8),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (!isSingleChoice)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _nextStep(steps),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor: accentColor.withOpacity(0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
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
          );
        },
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
                  if (isSpecial) {
                    context.go('/mode-selection');
                  } else {
                    setState(() {
                      journeyData[key] = opt['v'];
                    });
                    // Auto-advance for single choice
                    if (step['type'] == 'chips-big-single') {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        final steps = ref.read(journeyStepsProvider(widget.mode)).maybeWhen(
                          data: (data) => data,
                          orElse: () => [],
                        );
                        if (steps.isNotEmpty) {
                          _nextStep(steps);
                        }
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withOpacity(0.08) : Colors.white,
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
                      Text(opt['e'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt['l'],
                          style: TextStyle(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor.withOpacity(0.5) : const Color(0xFFFCE8E4),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${opt['e']} $label',
                  style: TextStyle(
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
        final DateTime? date = currentValue != null ? (currentValue as Timestamp).toDate() : null;
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
                  date != null ? "${date.day}/${date.month}/${date.year}" : 'Select Date',
                  style: const TextStyle(
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
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFCE8E4), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepBtn(Icons.remove, () {
                if (val > step['min']) {
                  setState(() => journeyData[key] = val - 1);
                }
              }),
              const SizedBox(width: 30),
              Column(
                children: [
                  Text(
                    '$val',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    step['unit'].toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD0B0B8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 30),
              _buildStepBtn(Icons.add, () {
                if (val < step['max']) {
                  setState(() => journeyData[key] = val + 1);
                }
              }),
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 24),
      ),
    );
  }
}
