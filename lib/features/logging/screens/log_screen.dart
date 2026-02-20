import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/log_provider.dart';
import '../../../models/daily_log_model.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  String selectedFlow = 'medium';
  String selectedMood = 'low';
  List<String> selectedSymptoms = ['Cramps', 'Headache'];
  final TextEditingController _noteController = TextEditingController();

  Future<void> _saveLog() async {
    final log = DailyLog(
      id: DateTime.now().toIso8601String().split('T')[0],
      date: DateTime.now(),
      flow: selectedFlow,
      mood: selectedMood, // ✅ fixed: was 'moods: [selectedMood]'
      symptoms: selectedSymptoms,
      note: _noteController.text,
    );

    await ref.read(logProvider.notifier).saveLog(log);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('log_saved'.tr())),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'log_title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
              Text(
                DateFormat('EEEE · MMM dd, yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('log_flow_label'.tr()),
              Row(
                children: [
                  _buildFlowBtn('🔴', 'flow_heavy'.tr(), 'heavy'),
                  const SizedBox(width: 10),
                  _buildFlowBtn('🟠', 'flow_medium'.tr(), 'medium'),
                  const SizedBox(width: 10),
                  _buildFlowBtn('🟡', 'flow_light'.tr(), 'light'),
                  const SizedBox(width: 10),
                  _buildFlowBtn('🤍', 'flow_none'.tr(), 'none'),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('log_mood_label'.tr()),
              Row(
                children: [
                  _buildMoodBtn('😔', 'low'),
                  const SizedBox(width: 8),
                  _buildMoodBtn('😐', 'okay'),
                  const SizedBox(width: 8),
                  _buildMoodBtn('🙂', 'good'),
                  const SizedBox(width: 8),
                  _buildMoodBtn('😊', 'great'),
                  const SizedBox(width: 8),
                  _buildMoodBtn('🥰', 'tense'),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('log_symptoms_label'.tr()),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _buildSymptomChip('🌀 Cramps'),
                  _buildSymptomChip('🤕 Headache'),
                  _buildSymptomChip('😴 Tired'),
                  _buildSymptomChip('🤢 Nausea'),
                  _buildSymptomChip('🌊 Bloating'),
                  _buildSymptomChip('💆 Back Pain'),
                  _buildSymptomChip('🍫 Cravings'),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('log_note_label'.tr()),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A3838),
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'How are you really feeling? (just for you)',
                  hintStyle: const TextStyle(color: Color(0xFFDDBEC0)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppColors.lightRose, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRose.withOpacity(0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: logState.isLoading ? null : _saveLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: logState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('log_save'.tr()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFFC0A0A8),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildFlowBtn(String icon, String label, String value) {
    final isSelected = selectedFlow == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFlow = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF5F6) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryRose : AppColors.border,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryRose.withOpacity(0.18),
                      offset: const Offset(0, 4),
                      blurRadius: 14,
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color:
                      isSelected ? AppColors.primaryRose : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodBtn(String emoji, String value) {
    final isSelected = selectedMood == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedMood = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FAF4) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFA8D0B8) : AppColors.border,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF64B482).withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  Widget _buildSymptomChip(String label) {
    final key = label.split(' ').last;
    final isSelected = selectedSymptoms.contains(key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedSymptoms.contains(key)) {
            selectedSymptoms.remove(key);
          } else {
            selectedSymptoms.add(key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F0FC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFC8B0E0) : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color:
                isSelected ? const Color(0xFF9870C0) : const Color(0xFFC0A0A8),
          ),
        ),
      ),
    );
  }
}
