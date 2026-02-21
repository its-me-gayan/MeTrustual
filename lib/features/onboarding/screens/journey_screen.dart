import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class JourneyScreen extends StatefulWidget {
  final String mode;
  const JourneyScreen({super.key, required this.mode});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  int currentStep = 0;
  final Map<String, dynamic> journeyData = {};

  late final List<Map<String, dynamic>> steps;
  late final Color accentColor;
  late final LinearGradient progressGradient;

  @override
  void initState() {
    super.initState();
    steps = _getJourneySteps(widget.mode);
    accentColor = _getModeColor(widget.mode);
    progressGradient = _getModeGradient(widget.mode);
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

  List<Map<String, dynamic>> _getJourneySteps(String mode) {
    if (mode == 'preg') {
      return [
        {
          'icon': '🤰',
          'q': 'Are you currently pregnant?',
          'sub':
              'This helps us set up the right tracker for you. No judgement either way.',
          'type': 'chips-big-single',
          'key': 'isPreg',
          'opts': [
            {'e': '✅', 'l': "Yes, I'm pregnant!", 'v': 'yes'},
            {'e': '🤔', 'l': 'I think I might be', 'v': 'maybe'},
            {
              'e': '🔄',
              'l': "Actually, I'm not — switch tracker",
              'v': 'switch',
              'special': true
            }
          ],
          'warn':
              'You can switch back to Period or Onboarding tracker anytime from your home screen.'
        },
        {
          'icon': '📅',
          'q': 'Do you know your due date?',
          'sub':
              'If yes, enter it. If not, enter your last period start date and we\'ll calculate.',
          'type': 'due-date',
          'key': 'dueDate'
        },
        {
          'icon': '👶',
          'q': 'Is this your first pregnancy?',
          'sub': 'This personalises your week-by-week tips and what to expect.',
          'type': 'chips-big-single',
          'key': 'firstPreg',
          'opts': [
            {'e': '🌱', 'l': 'Yes — my first!', 'v': 'first'},
            {'e': '👧', 'l': 'I have one child', 'v': 'second'},
            {'e': '👨‍👩‍👧‍👦', 'l': 'Two or more children', 'v': 'multiple'}
          ]
        },
        {
          'icon': '🩺',
          'q': 'Any conditions to track together?',
          'sub':
              'Optional — select any for extra personalised support and reminders.',
          'type': 'chips-multi',
          'key': 'conditions',
          'opts': [
            {'e': '🩺', 'l': 'Gestational Diabetes'},
            {'e': '💓', 'l': 'High Blood Pressure'},
            {'e': '🤢', 'l': 'Severe Morning Sickness'},
            {'e': '🩸', 'l': 'Anaemia'},
            {'e': '🧠', 'l': 'Prenatal Anxiety'},
            {'e': '😴', 'l': 'Sleep Issues'},
            {'e': '✨', 'l': 'All good — none'}
          ]
        },
        {
          'icon': '💙',
          'q': 'What support do you want from us?',
          'sub':
              'We\'ll send you the content that matters most. Adjust anytime.',
          'type': 'chips-multi',
          'key': 'support',
          'opts': [
            {'e': '📋', 'l': 'Weekly baby updates'},
            {'e': '🩺', 'l': 'Appointment reminders'},
            {'e': '👶', 'l': 'Kick counter alerts'},
            {'e': '🌿', 'l': 'Nutrition & wellness tips'},
            {'e': '🧘', 'l': 'Mental health & mindfulness'},
            {'e': '📖', 'l': 'Birth & newborn prep'}
          ]
        }
      ];
    } else if (mode == 'ovul') {
      return [
        {
          'icon': '🌿',
          'q': 'What\'s your main goal?',
          'sub':
              'This shapes your insights, alerts, and what tools we highlight for you.',
          'type': 'chips-big-single',
          'key': 'goal',
          'opts': [
            {'e': '👶', 'l': 'Trying to conceive (TTC)', 'v': 'ttc'},
            {'e': '🌿', 'l': 'Natural family planning', 'v': 'nfp'},
            {'e': '🔬', 'l': 'Understanding my body & cycle', 'v': 'understand'}
          ]
        },
        {
          'icon': '📅',
          'q': 'When did your last period start?',
          'sub':
              'We calculate your fertile window from this. Ovulation is usually ~14 days before your next period.',
          'type': 'date',
          'key': 'lastPeriod',
          'skip': 'Skip for now'
        },
        {
          'icon': '🔁',
          'q': 'How long is your cycle usually?',
          'sub': 'Knowing this makes ovulation predictions much more accurate.',
          'type': 'stepper',
          'key': 'cycleLen',
          'min': 18,
          'max': 45,
          'def': 28,
          'unit': 'days',
          'skip': 'Not sure yet'
        },
        {
          'icon': '🌡️',
          'q': 'What do you currently track?',
          'sub':
              'Select all that apply — we\'ll guide you on using each method together.',
          'type': 'chips-multi',
          'key': 'methods',
          'opts': [
            {'e': '🌡️', 'l': 'BBT (Basal Body Temp)'},
            {'e': '💊', 'l': 'OPK / LH Test Strips'},
            {'e': '💧', 'l': 'Cervical Mucus'},
            {'e': '📅', 'l': 'Period dates only'},
            {'e': '🩸', 'l': 'Mid-cycle spotting'},
            {'e': '🆕', 'l': 'Nothing yet — just starting!'}
          ]
        },
        {
          'icon': '🔔',
          'q': 'How should we alert you?',
          'sub': 'We only send what you choose. You can change this anytime.',
          'type': 'chips-multi',
          'key': 'alerts',
          'opts': [
            {'e': '🟢', 'l': 'Fertile window opens'},
            {'e': '🎯', 'l': 'Peak ovulation day'},
            {'e': '📉', 'l': 'Fertile window closing'},
            {'e': '📅', 'l': 'Period due reminder'},
            {'e': '🌡️', 'l': 'BBT reminder each morning'},
            {'e': '💊', 'l': 'OPK test reminder'}
          ]
        }
      ];
    } else {
      return [
        {
          'icon': '🩸',
          'q': 'When did your last period start?',
          'sub':
              'This helps us predict your next period and fertile window accurately.',
          'type': 'date',
          'key': 'lastPeriod',
          'skip': 'Not sure / this is my first time tracking'
        },
        {
          'icon': '📅',
          'q': 'How long is your cycle usually?',
          'sub':
              'Day 1 of one period to Day 1 of the next. Most cycles are 21–35 days.',
          'type': 'stepper',
          'key': 'cycleLen',
          'min': 18,
          'max': 45,
          'def': 28,
          'unit': 'days',
          'skip': 'Not sure yet — we\'ll learn!'
        },
        {
          'icon': '🗓️',
          'q': 'How many days does your period last?',
          'sub': 'Include light spotting days. Most periods last 3–7 days.',
          'type': 'stepper',
          'key': 'periodLen',
          'min': 1,
          'max': 10,
          'def': 5,
          'unit': 'days'
        },
        {
          'icon': '💧',
          'q': 'How would you describe your usual flow?',
          'sub':
              'Helps us give you better predictions and product recommendations.',
          'type': 'chips-single',
          'key': 'flow',
          'opts': [
            {'e': '💧', 'l': 'Light', 'v': 'light'},
            {'e': '🟠', 'l': 'Medium', 'v': 'medium'},
            {'e': '🔴', 'l': 'Heavy', 'v': 'heavy'},
            {'e': '🔀', 'l': 'Varies', 'v': 'varies'}
          ]
        },
        {
          'icon': '🌀',
          'q': 'Symptoms you often get?',
          'sub':
              'Select all that apply — we\'ll personalise your care tips each phase.',
          'type': 'chips-multi',
          'key': 'symptoms',
          'opts': [
            {'e': '🌀', 'l': 'Cramps'},
            {'e': '🤕', 'l': 'Headache'},
            {'e': '😴', 'l': 'Fatigue'},
            {'e': '🤢', 'l': 'Nausea'},
            {'e': '🌊', 'l': 'Bloating'},
            {'e': '💆', 'l': 'Back Pain'},
            {'e': '🍫', 'l': 'Cravings'},
            {'e': '😤', 'l': 'Mood Swings'},
            {'e': '🌡️', 'l': 'Breast Tenderness'},
            {'e': '✨', 'l': 'None usually'}
          ]
        }
      ];
    }
  }

  void _nextStep() {
    if (currentStep < steps.length - 1) {
      setState(() => currentStep++);
    } else {
      context.go('/home');
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
    final step = steps[currentStep];
    final progress = (currentStep + 1) / steps.length;

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
              // Header
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
                        child: const Icon(Icons.chevron_left, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE8E4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                decoration: BoxDecoration(
                                  gradient: progressGradient,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Step ${currentStep + 1} of ${steps.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD0B0B8),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(step['icon'], style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        step['q'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB09090),
                          fontWeight: FontWeight.w600,
                          lineHeight: 1.6,
                        ),
                      ),
                      if (step['warn'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: accentColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            '💡 ${step['warn']}',
                            style: TextStyle(
                                fontSize: 11,
                                color: accentColor,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildStepInput(step),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      shadowColor: accentColor.withOpacity(0.35),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(accentColor),
                    ),
                    child: Text(
                      currentStep == steps.length - 1
                          ? "Done! Let's go →"
                          : "Continue →",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepInput(Map<String, dynamic> step) {
    switch (step['type']) {
      case 'date':
      case 'due-date':
        return Column(
          children: [
            if (step['type'] == 'due-date') ...[
              _buildBigChip(
                '📅 Yes, I know my due date',
                journeyData['dueDateKnown'] != false,
                () => setState(() => journeyData['dueDateKnown'] = true),
              ),
              const SizedBox(height: 10),
              _buildBigChip(
                '🩸 Use my last period start instead',
                journeyData['dueDateKnown'] == false,
                () => setState(() => journeyData['dueDateKnown'] = false),
              ),
              const SizedBox(height: 20),
            ],
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null)
                  setState(() => journeyData[step['key']] = date.toString());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: accentColor.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      journeyData[step['key']] ?? 'Select Date',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: journeyData[step['key']] == null
                            ? Colors.grey
                            : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (step['skip'] != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _nextStep,
                child: Text(
                  step['skip'],
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD0B0B8),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline),
                ),
              ),
            ]
          ],
        );
      case 'stepper':
        final val = journeyData[step['key']] ?? step['def'];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFCE8E4), width: 1.5),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['unit'],
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD0B0B8))),
                      Text(val.toString(),
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: accentColor)),
                    ],
                  ),
                  const Spacer(),
                  _buildStepperBtn(Icons.remove, () {
                    if (val > step['min'])
                      setState(() => journeyData[step['key']] = val - 1);
                  }),
                  const SizedBox(width: 12),
                  _buildStepperBtn(Icons.add, () {
                    if (val < step['max'])
                      setState(() => journeyData[step['key']] = val + 1);
                  }),
                ],
              ),
            ),
            if (step['skip'] != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _nextStep,
                child: Text(
                  step['skip'],
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD0B0B8),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline),
                ),
              ),
            ]
          ],
        );
      case 'chips-single':
      case 'chips-multi':
        final isMulti = step['type'] == 'chips-multi';
        final selected = journeyData[step['key']] ?? (isMulti ? [] : null);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: (step['opts'] as List).map((o) {
            final on = isMulti ? selected.contains(o['l']) : selected == o['v'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isMulti) {
                    if (selected.contains(o['l']))
                      selected.remove(o['l']);
                    else
                      selected.add(o['l']);
                    journeyData[step['key']] = selected;
                  } else {
                    journeyData[step['key']] = o['v'];
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: on ? accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: on ? accentColor : const Color(0xFFFCE8E4),
                      width: 1.5),
                ),
                child: Text(
                  '${o['e']} ${o['l']}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: on ? Colors.white : AppColors.textDark),
                ),
              ),
            );
          }).toList(),
        );
      case 'chips-big-single':
        final selected = journeyData[step['key']];
        return Column(
          children: (step['opts'] as List).map((o) {
            final on = selected == o['v'];
            final isSpecial = o['special'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildBigChip(
                '${o['e']} ${o['l']}',
                on,
                () {
                  if (isSpecial)
                    context.go('/mode-selection');
                  else
                    setState(() => journeyData[step['key']] = o['v']);
                },
                isSpecial: isSpecial,
              ),
            );
          }).toList(),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBigChip(String text, bool on, VoidCallback onTap,
      {bool isSpecial = false}) {
    Color bgColor = on ? accentColor : Colors.white;
    Color textColor = on ? Colors.white : AppColors.textDark;
    Color borderColor = on ? accentColor : const Color(0xFFFCE8E4);

    if (isSpecial && !on) {
      bgColor = const Color(0xFFF5F5F5);
      textColor = const Color(0xFF707070);
      borderColor = const Color(0xFFE0E0E0);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            if (isSpecial)
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 24),
      ),
    );
  }
}
