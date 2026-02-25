import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/utils/calendar_engine.dart';
import '../../../models/calendar_day_model.dart';
import '../providers/home_provider.dart';
import 'calendar_day_cell.dart';
import 'day_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Key for family provider
// ─────────────────────────────────────────────────────────────
class _MonthModeKey {
  final int year;
  final int month;
  final String mode;
  final String uid;

  const _MonthModeKey({
    required this.year,
    required this.month,
    required this.mode,
    required this.uid,
  });

  @override
  bool operator ==(Object other) =>
      other is _MonthModeKey &&
      other.year == year &&
      other.month == month &&
      other.mode == mode &&
      other.uid == uid;

  @override
  int get hashCode => Object.hash(year, month, mode, uid);
}

// ─────────────────────────────────────────────────────────────
//  Streams log summaries from Firestore for a given month
// ─────────────────────────────────────────────────────────────
final _monthLogMapProvider =
    StreamProvider.family<Map<String, LogDaySummary>, _MonthModeKey>(
        (ref, key) async* {
  if (key.uid.isEmpty) {
    yield {};
    return;
  }

  final firestore = ref.watch(firestoreProvider);
  final firstDay = DateTime(key.year, key.month, 1);
  final lastDay = DateTime(key.year, key.month + 1, 0);
  final startKey = DateFormat('yyyy-MM-dd').format(firstDay);
  final endKey = DateFormat('yyyy-MM-dd').format(lastDay);

  yield* firestore
      .collection('users')
      .doc(key.uid)
      .collection('logs')
      .doc(key.mode)
      .collection('entries')
      .where('date', isGreaterThanOrEqualTo: startKey)
      .where('date', isLessThanOrEqualTo: endKey)
      .snapshots()
      .map((snap) {
    final map = <String, LogDaySummary>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      map[doc.id] = LogDaySummary(
        flow: d['flow'] as String?,
        mood: d['mood'] as String?,
        symptoms: List<String>.from(d['symptoms'] as List? ?? []),
        hasNote: (d['note'] as String? ?? '').isNotEmpty,
      );
    }
    return map;
  });
});

// ─────────────────────────────────────────────────────────────
//  Builds CalendarDayModel list for a given month offset
// ─────────────────────────────────────────────────────────────
final _monthDaysProvider =
    Provider.family<AsyncValue<List<CalendarDayModel>>, int>((ref, offset) {
  final auth = ref.watch(firebaseAuthProvider);
  final mode = ref.watch(modeProvider);
  final homeData = ref.watch(homeDataProvider);
  final uid = auth.currentUser?.uid ?? '';

  final now = DateTime.now();
  final displayMonth = DateTime(now.year, now.month + offset, 1);

  final logMapAsync = ref.watch(_monthLogMapProvider(_MonthModeKey(
    year: displayMonth.year,
    month: displayMonth.month,
    mode: mode,
    uid: uid,
  )));

  return logMapAsync.when(
    data: (logMap) {
      DateTime lastPeriodStart;
      int cycleLength;

      try {
        if (homeData != null && homeData['lastCycle'] != null) {
          final dynamic lastCycle = homeData['lastCycle'];
          lastPeriodStart = lastCycle.startDate as DateTime;
          final dynamic prediction = homeData['prediction'];
          cycleLength = (prediction?.averageLength as num?)?.toInt() ?? 28;
        } else {
          lastPeriodStart = DateTime(now.year, now.month, 1);
          cycleLength = 28;
        }
      } catch (_) {
        lastPeriodStart = DateTime(now.year, now.month, 1);
        cycleLength = 28;
      }

      final engine = CalendarEngine(
        lastPeriodStart: lastPeriodStart,
        cycleLength: cycleLength,
        periodLength: 5,
        today: now,
      );

      return AsyncValue.data(engine.buildMonth(
        year: displayMonth.year,
        month: displayMonth.month,
        logMap: logMap,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ═══════════════════════════════════════════════════════════════
//  MiniCalendar — drop-in replacement
// ═══════════════════════════════════════════════════════════════
class MiniCalendar extends ConsumerStatefulWidget {
  const MiniCalendar({super.key});

  @override
  ConsumerState<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends ConsumerState<MiniCalendar> {
  static const int _initialPage = 500;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigate(int direction) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      _pageController.page!.round() + direction,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Each cell = (screenWidth - 44 padding) / 7 columns
    // Cell height = day number bubble + cycle badge + dots ≈ same as width
    // We use AspectRatio 1.0 per cell so the grid is perfectly square cells.
    // Total height = header(34) + weekdays(20) + 6 rows of square cells
    // Cell width ≈ (screenWidth - 44) / 7 ≈ ~44px on 375px screen → height per row ~44px
    // So 6 rows = ~264px. We use LayoutBuilder to compute exactly.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Legend ──
        _buildLegend(),
        const SizedBox(height: 8),

        // ── Swipeable calendar — use LayoutBuilder so we can size precisely ──
        LayoutBuilder(builder: (context, constraints) {
          final cellSize = constraints.maxWidth / 7;
          // Each cell row: cycle badge (10) + bubble (cellSize * 0.76) + dots (9)
          // We'll use a fixed cell height = cellSize * 1.05 to keep it square-ish
          // Header = 34, weekdays = 18, 6 rows of cells
          final rowH = cellSize * 1.08;
          final totalH = 34.0 + 18.0 + (6 * rowH);

          return SizedBox(
            height: totalH,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, page) {
                final offset = page - _initialPage;
                return _CalendarMonthPage(
                  offset: offset,
                  onNavigate: _navigate,
                  cellSize: cellSize,
                  rowHeight: rowH,
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: [
        _legendItem(
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRose.withOpacity(0.55),
            ),
          ),
          'Period',
        ),
        _legendItem(
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sageGreen.withOpacity(0.45),
            ),
          ),
          'Fertile',
        ),
        _legendItem(
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRose.withOpacity(0.08),
              border: Border.all(
                color: AppColors.primaryRose.withOpacity(0.4),
                width: 1.2,
              ),
            ),
          ),
          'Predicted',
        ),
        _legendItem(
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.primaryRose, width: 1.8),
            ),
          ),
          'Today',
        ),
      ],
    );
  }

  Widget _legendItem(Widget swatch, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      swatch,
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  Single month page
// ─────────────────────────────────────────────────────────────
class _CalendarMonthPage extends ConsumerWidget {
  final int offset;
  final Function(int) onNavigate;
  final double cellSize;
  final double rowHeight;

  static const List<String> _weekdays = [
    'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'
  ];

  const _CalendarMonthPage({
    required this.offset,
    required this.onNavigate,
    required this.cellSize,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final displayMonth = DateTime(now.year, now.month + offset, 1);
    final monthLabel = DateFormat('MMMM yyyy').format(displayMonth);
    final calendarAsync = ref.watch(_monthDaysProvider(offset));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Month title + nav arrows ──
        SizedBox(
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrow(icon: Icons.chevron_left_rounded, onTap: () => onNavigate(-1)),
              Text(
                monthLabel,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              _NavArrow(icon: Icons.chevron_right_rounded, onTap: () => onNavigate(1)),
            ],
          ),
        ),

        // ── Weekday headers ──
        SizedBox(
          height: 18,
          child: Row(
            children: _weekdays.map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD0A8B0),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),

        // ── Grid ──
        Expanded(
          child: calendarAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.primaryRose,
                  strokeWidth: 1.8,
                ),
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Could not load calendar',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            data: (days) => _DayGrid(days: days, rowHeight: rowHeight),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Day grid — square cells, 7 columns
// ─────────────────────────────────────────────────────────────
class _DayGrid extends StatelessWidget {
  final List<CalendarDayModel> days;
  final double rowHeight;

  const _DayGrid({required this.days, required this.rowHeight});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        // childAspectRatio > 1 = cell wider than tall (what we want for compact rows)
        // We want each cell to be exactly rowHeight tall and cellWidth wide
        // childAspectRatio = cellWidth / rowHeight
        // Since cellWidth = totalWidth / 7, and we set rowHeight = cellWidth * 1.08,
        // childAspectRatio = 1 / 1.08 ≈ 0.926
        // But we pass rowHeight directly and compute from it.
        mainAxisExtent: rowHeight,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day.type == DayType.empty) return const SizedBox();

        return CalendarDayCell(
          day: day,
          onTap: () => _openDaySheet(context, day),
        );
      },
    );
  }

  void _openDaySheet(BuildContext context, CalendarDayModel day) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DayDetailSheet(day: day),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Nav arrow button
// ─────────────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRose.withOpacity(0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.primaryRose),
      ),
    );
  }
}
