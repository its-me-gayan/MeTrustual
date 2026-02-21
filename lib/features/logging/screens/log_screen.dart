import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
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
    final currentMode = ref.watch(modeProvider);

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
                    _getPageTitle(currentMode),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getPageSub(currentMode),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _buildModeSpecificLogContent(currentMode),
              const SizedBox(height: 20),
              _buildSaveButton(currentMode),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle(String currentMode) {
    switch (currentMode) {
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

  String _getPageSub(String currentMode) {
    switch (currentMode) {
      case 'period':
        return 'Thursday · Feb 21, 2026';
      case 'preg':
        return 'Week 24 · Thursday, Feb 21';
      case 'ovul':
        return 'Cycle Day 14 · Feb 21, 2026';
      default:
        return 'Thursday · Feb 21, 2026';
    }
  }

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
          '💧 Water (glasses)',
          waterGlasses,
          0,
          15,
          (val) => setState(() => waterGlasses = val),
          '🌙 Sleep (hrs)',
          sleepHours,
          0,
          12,
          (val) => setState(() => sleepHours = val),
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
          '💧 Water (glasses)',
          waterGlassesPreg,
          0,
          15,
          (val) => setState(() => waterGlassesPreg = val),
          '⚖️ Weight (kg)',
          weightKg,
          50,
          120,
          (val) => setState(() => weightKg = val),
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
            '🏜️ Dry / None',
            '🍬 Sticky',
            '🥛 Creamy',
            '💧 Watery',
            '🥚 Egg White (peak!)'
          ],
          selectedCervicalMucus,
          (chip) => setState(() => selectedCervicalMucus = chip),
          const Color(0xFF5A8E6A),
        ),
        _buildSectionTitle('OPK Test result?'),
        _buildChipsSingle(
          [
            '⬜ Negative',
            '🟡 Low',
            '🟠 High',
            '🎯 Peak!',
            '⏭️ Didn\'t test'
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
            '🩸 Mid-cycle spotting',
            '💫 Ovulation pain (Mittelschmerz)',
            '🌿 High libido',
            '🌡️ Feeling warm'
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
              color: isSelected
                  ? AppColors.primaryRose.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected ? AppColors.primaryRose : const Color(0xFFFCE8E4),
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
                    color:
                        isSelected ? AppColors.primaryRose : AppColors.textDark,
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
      case 'period':
        currentSelectedMood = selectedMoodPeriod;
        break;
      case 'preg':
        currentSelectedMood = selectedMoodPreg;
        break;
      case 'ovul':
        currentSelectedMood = selectedMoodOvul;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: moods.map((mood) {
        final isSelected = currentSelectedMood == mood;
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
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accentColor : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Text(mood, style: const TextStyle(fontSize: 28)),
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
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEFF), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            '👶 Kick Counter — Today',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A70B0)),
          ),
          const SizedBox(height: 10),
          Text(
            kicks.toString(),
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4A70B0)),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => kicks++),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF4A70B0).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Center(
                  child: Text('👶', style: TextStyle(fontSize: 32))),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap when you feel baby move — aim for 10 kicks in 2 hours',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7090C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildBBTInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8FAF0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌡️ Basal Body Temperature',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5A8E6A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '36.70',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8FAF0)),
                    ),
                  ),
                  onChanged: (val) => bbt = double.tryParse(val) ?? bbt,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '°C',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5A8E6A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'taken immediately on waking, before getting up',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8Aae8a)),
          ),
        ],
      ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Text(
              chip,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textMid,
              ),
            ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFFCE8E4),
                width: 1.5,
              ),
            ),
            child: Text(
              chip,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textMid,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogStepperRow(String l1, int v1, int min1, int max1,
      Function(int) onC1, String l2, dynamic v2, int min2, int max2,
      Function(int) onC2, Color color) {
    return Row(
      children: [
        Expanded(child: _buildLogStepper(l1, v1, min1, max1, onC1, color)),
        const SizedBox(width: 12),
        Expanded(child: _buildLogStepper(l2, v2, min2, max2, onC2, color)),
      ],
    );
  }

  Widget _buildLogStepper(String label, dynamic value, int min, int max,
      Function(int) onChanged, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepBtn(Icons.remove, () {
                if (value > min) onChanged(value - 1);
              }, color),
              Text(
                value.toString(),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color),
              ),
              _buildStepBtn(Icons.add, () {
                if (value < max) onChanged(value + 1);
              }, color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildNoteField(String initial, Function(String) onChanged) {
    return TextField(
      maxLines: 3,
      controller: TextEditingController(text: initial),
      decoration: InputDecoration(
        hintText: 'Just for you — how are you really feeling?',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFCE8E4), width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSaveButton(String mode) {
    Color color = _getAccentColor(mode);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.go('/home'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          mode == 'preg' ? 'Save today\'s log 💙' : 'Save today\'s log ✓',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
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
