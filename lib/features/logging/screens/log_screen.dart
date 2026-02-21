import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  // This should ideally come from a global state/provider
  String currentMode = 'period'; // period | preg | ovul

  // Period Mode State
  String? selectedFlow;
  String? selectedMoodPeriod;
  List<String> selectedSymptomsPeriod = [];
  int waterGlasses = 6;
  int sleepHours = 7;
  String periodNote = 'Feeling a bit drained. Cramps are manageable today.';

  // Pregnancy Mode State
  int kicks = 0;
  String? selectedMoodPreg;
  List<String> selectedSymptomsPreg = [];
  int waterGlassesPreg = 8;
  int weightKg = 64;
  String pregNote = '';

  // Ovulation Mode State
  double bbt = 36.72;
  String? selectedCervicalMucus;
  String? selectedOpkResult;
  String? selectedMoodOvul;
  List<String> selectedSymptomsOvul = [];
  String ovulNote = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textDark, size: 20),
                    onPressed: () => context.go('/home'),
                  ),
                  Text(
                    _getPageTitle(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getPageSub(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _buildModeSpecificLogContent(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (currentMode) {
      case 'period': return 'How are you? 🌸';
      case 'preg': return 'Daily Log 💙';
      case 'ovul': return 'Daily Log 🌿';
      default: return 'Daily Log';
    }
  }

  String _getPageSub() {
    // This should be dynamic based on date
    return 'Thursday · Feb 21, 2026';
  }

  Widget _buildModeSpecificLogContent() {
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

  Widget _buildPeriodLogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Flow today?'),
        _buildFlowSelection(),
        _buildSectionTitle('Mood?'),
        _buildMoodSelection('period'),
        _buildSectionTitle('Physical symptoms?'),
        _buildChipsMulti(
          [
            '🌀 Cramps', '🤕 Headache', '😴 Fatigue', '🤢 Nausea',
            '🌊 Bloating', '💆 Back Pain', '🍫 Cravings', '😤 Mood Swings',
            '🌡️ Breast Tenderness', '✚ More'
          ],
          selectedSymptomsPeriod,
          (chip) => setState(() {
            if (selectedSymptomsPeriod.contains(chip)) {
              selectedSymptomsPeriod.remove(chip);
            } else {
              selectedSymptomsPeriod.add(chip);
            }
          }),
          AppColors.primaryRose,
        ),
        _buildSectionTitle('Wellness'),
        _buildLogStepperRow(
          '💧 Water (glasses)', waterGlasses, 0, 15, (val) => setState(() => waterGlasses = val),
          '🌙 Sleep (hrs)', sleepHours, 0, 12, (val) => setState(() => sleepHours = val),
          AppColors.primaryRose,
        ),
        _buildSectionTitle('Note to self 🌷'),
        _buildNoteField(periodNote, (text) => periodNote = text),
      ],
    );
  }

  Widget _buildPregnancyLogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKickCounter(),
        _buildSectionTitle('How are you feeling?'),
        _buildMoodSelection('preg'),
        _buildSectionTitle('Symptoms today?'),
        _buildChipsMulti(
          [
            '🤢 Nausea', '🔥 Heartburn', '😴 Fatigue', '💆 Back Pain',
            '🦵 Leg Cramps', '🌊 Swelling', '😰 Anxiety', '😴 Insomnia',
            '🤯 Brain Fog', '✨ Feeling great!'
          ],
          selectedSymptomsPreg,
          (chip) => setState(() {
            if (selectedSymptomsPreg.contains(chip)) {
              selectedSymptomsPreg.remove(chip);
            } else {
              selectedSymptomsPreg.add(chip);
            }
          }),
          const Color(0xFF4A70B0),
        ),
        _buildSectionTitle('Wellness'),
        _buildLogStepperRow(
          '💧 Water (glasses)', waterGlassesPreg, 0, 15, (val) => setState(() => waterGlassesPreg = val),
          '⚖️ Weight (kg)', weightKg, 50, 120, (val) => setState(() => weightKg = val),
          const Color(0xFF4A70B0),
        ),
        _buildSectionTitle('Appointment notes 🩺'),
        _buildNoteField(pregNote, (text) => pregNote = text),
      ],
    );
  }

  Widget _buildOvulationLogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBBTInput(),
        _buildSectionTitle('Cervical mucus?'),
        _buildChipsSingle(
          [
            '🏜️ Dry / None', '🍬 Sticky', '🥛 Creamy', '💧 Watery', '🥚 Egg White (peak!)'
          ],
          selectedCervicalMucus,
          (chip) => setState(() => selectedCervicalMucus = chip),
          const Color(0xFF5A8E6A),
        ),
        _buildSectionTitle('OPK Test result?'),
        _buildChipsSingle(
          [
            '⬜ Negative', '🟡 Low', '🟠 High', '🎯 Peak!', '⏭️ Didn\'t test'
          ],
          selectedOpkResult,
          (chip) => setState(() => selectedOpkResult = chip),
          const Color(0xFF5A8E6A),
        ),
        _buildSectionTitle('Mood & energy?'),
        _buildMoodSelection('ovul'),
        _buildSectionTitle('Other symptoms?'),
        _buildChipsMulti(
          [
            '🩸 Mid-cycle spotting', '💫 Ovulation pain (Mittelschmerz)',
            '🌿 High libido', '🌡️ Feeling warm'
          ],
          selectedSymptomsOvul,
          (chip) => setState(() {
            if (selectedSymptomsOvul.contains(chip)) {
              selectedSymptomsOvul.remove(chip);
            } else {
              selectedSymptomsOvul.add(chip);
            }
          }),
          const Color(0xFF5A8E6A),
        ),
        _buildSectionTitle('Note 🌷'),
        _buildNoteField(ovulNote, (text) => ovulNote = text),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFFC0A0A8),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryRose.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primaryRose : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(flow['icon']!, style: const TextStyle(fontSize: 28)),
                Text(
                  flow['label']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primaryRose : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodSelection(String mode) {
    final moods = ['😔', '😐', '🙂', '😊', '🥰'];
    Color accentColor = _getAccentColor(mode);
    String? currentSelectedMood;
    switch (mode) {
      case 'period': currentSelectedMood = selectedMoodPeriod; break;
      case 'preg': currentSelectedMood = selectedMoodPreg; break;
      case 'ovul': currentSelectedMood = selectedMoodOvul; break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: moods.map((mood) {
        final isSelected = currentSelectedMood == mood;
        return GestureDetector(
          onTap: () => setState(() {
            switch (mode) {
              case 'period': selectedMoodPeriod = mood; break;
              case 'preg': selectedMoodPreg = mood; break;
              case 'ovul': selectedMoodOvul = mood; break;
            }
          }),
          child: Container(
            width: 48, height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accentColor : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Text(mood, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipsMulti(List<String> chips, List<String> selectedChips, Function(String) onTap, Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        final isSelected = selectedChips.contains(chip);
        return GestureDetector(
          onTap: () => onTap(chip),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accentColor : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Text(
              chip,
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
  }

  Widget _buildChipsSingle(List<String> chips, String? selectedChip, Function(String) onTap, Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        final isSelected = selectedChip == chip;
        return GestureDetector(
          onTap: () => onTap(chip),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accentColor : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Text(
              chip,
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
  }

  Widget _buildLogStepperRow(
    String label1, int val1, int min1, int max1, ValueChanged<int> onChanged1,
    String label2, int val2, int min2, int max2, ValueChanged<int> onChanged2,
    Color accentColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildLogStepper(label1, val1, min1, max1, onChanged1, accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLogStepper(label2, val2, min2, max2, onChanged2, accentColor),
        ),
      ],
    );
  }

  Widget _buildLogStepper(
      String label, int value, int min, int max, ValueChanged<int> onChanged, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepperButton(Icons.remove, () {
                if (value > min) onChanged(value - 1);
              }, accentColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accentColor)),
              ),
              _buildStepperButton(Icons.add, () {
                if (value < max) onChanged(value + 1);
              }, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap, Color accentColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
    );
  }

  Widget _buildNoteField(String initialValue, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Just for you — how are you really feeling?',
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.textMuted),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildKickCounter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A70B0).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '👶 Kick Counter — Today',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            kicks.toString(),
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF4A70B0)),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => kicks++),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4A70B0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('👶', style: TextStyle(fontSize: 32))),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap when you feel baby move — aim for 10 kicks in 2 hours',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF7090C0), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildBBTInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A8E6A).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌡️ Basal Body Temperature',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: TextEditingController(text: bbt.toStringAsFixed(2)),
                  onChanged: (text) {
                    final value = double.tryParse(text);
                    if (value != null) setState(() => bbt = value);
                  },
                  decoration: InputDecoration(
                    hintText: '36.70',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                  ),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF5A8E6A)),
                ),
              ),
              const Text(
                '°C',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            '— taken immediately on waking, before getting up',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    Color buttonColor = AppColors.primaryRose;
    switch (currentMode) {
      case 'preg': buttonColor = const Color(0xFF4A70B0); break;
      case 'ovul': buttonColor = const Color(0xFF5A8E6A); break;
    }
    String buttonText = 'Save today\'s log';
    switch (currentMode) {
      case 'period': buttonText += ' ✓'; break;
      case 'preg': buttonText += ' 💙'; break;
      case 'ovul': buttonText += ' 🌿'; break;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          // Handle saving log data based on currentMode
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Log saved for $currentMode mode!'))
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          shadowColor: buttonColor.withOpacity(0.35),
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(buttonColor),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Color _getAccentColor(String mode) {
    switch (mode) {
      case 'preg': return const Color(0xFF4A70B0);
      case 'ovul': return const Color(0xFF5A8E6A);
      default: return AppColors.primaryRose;
    }
  }
}
