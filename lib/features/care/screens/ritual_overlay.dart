import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────
//  DATE KEY  e.g. "2026-02-24"  — resets at local midnight
// ─────────────────────────────────────────────────────────
String _todayKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────
//  RITUAL OVERLAY  (main checklist sheet)
// ─────────────────────────────────────────────────────────
class RitualOverlay extends ConsumerStatefulWidget {
  final List<Map<String, String>> rituals;
  final Color color;
  final String phase;

  const RitualOverlay({
    super.key,
    required this.rituals,
    required this.color,
    required this.phase,
  });

  @override
  ConsumerState<RitualOverlay> createState() => _RitualOverlayState();
}

class _RitualOverlayState extends ConsumerState<RitualOverlay>
    with TickerProviderStateMixin {
  final Set<int> _checked = {};
  bool _loading = true;

  late AnimationController _confettiCtrl;
  bool _showConfetti = false;
  late AnimationController _bannerCtrl;
  late Animation<double> _bannerScale;

  bool get _allDone =>
      widget.rituals.isNotEmpty && _checked.length == widget.rituals.length;

  DocumentReference? get _docRef {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return null;
    return ref
        .read(firestoreProvider)
        .collection('users')
        .doc(uid)
        .collection('ritual_completions')
        .doc(_todayKey());
  }

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _bannerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bannerScale =
        CurvedAnimation(parent: _bannerCtrl, curve: Curves.elasticOut);
    _load();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  // ── Load today's completions ─────────────────────────
  Future<void> _load() async {
    try {
      final snap = await _docRef?.get();
      if (snap != null && snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final raw = data?[widget.phase];
        if (raw is List) {
          for (final idx in raw) {
            if (idx is int && idx < widget.rituals.length) _checked.add(idx);
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      if (_allDone) _bannerCtrl.value = 1.0;
    }
  }

  // ── Save after every change ──────────────────────────
  Future<void> _save() async {
    try {
      await _docRef?.set(
        {
          widget.phase: _checked.toList()..sort(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // ── Mark one ritual complete (called by timer sheet) ─
  void _complete(int index) {
    final wasAllDone = _allDone;
    setState(() => _checked.add(index));
    if (_allDone && !wasAllDone) _celebrate();
    _save();
  }

  // ── Mark all done ────────────────────────────────────
  void _markAllDone() {
    final wasAllDone = _allDone;
    setState(() {
      for (int i = 0; i < widget.rituals.length; i++) _checked.add(i);
    });
    if (!wasAllDone) _celebrate();
    _save();
  }

  // ── Uncheck (tap done item to undo) ──────────────────
  void _uncheck(int index) {
    setState(() {
      _checked.remove(index);
      if (_showConfetti) {
        _showConfetti = false;
        _confettiCtrl.reset();
      }
      _bannerCtrl.reverse();
    });
    _save();
  }

  void _celebrate() {
    setState(() => _showConfetti = true);
    _bannerCtrl.forward(from: 0);
    _confettiCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  // ── Open timer sheet for one ritual ─────────────────
  void _openTimer(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimerSheet(
        ritual: widget.rituals[index],
        color: widget.color,
        onComplete: () {
          Navigator.pop(context); // close timer sheet
          _complete(index);
        },
      ),
    );
  }

  Color get _bgColor {
    if (widget.color == const Color(0xFF4A70B0)) return const Color(0xFFF4F7FF);
    if (widget.color == const Color(0xFF5A8E6A)) return const Color(0xFFF2FBF5);
    return const Color(0xFFFEF6F0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Today's Ritual",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_checked.length}/${widget.rituals.length}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: widget.rituals.isEmpty
                        ? 0
                        : _checked.length / widget.rituals.length,
                    minHeight: 4,
                    backgroundColor: widget.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Celebration banner
              ScaleTransition(
                scale: _bannerScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: _allDone ? 50 : 0,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: widget.color.withOpacity(0.3), width: 1.5),
                  ),
                  child: _allDone
                      ? Center(
                          child: Text(
                            '🎉 All rituals complete for today!',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: widget.color,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Checklist
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(widget.color),
                          strokeWidth: 2.5,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: widget.rituals.length,
                        itemBuilder: (_, i) => _RitualTile(
                          ritual: widget.rituals[i],
                          isDone: _checked.contains(i),
                          color: widget.color,
                          // Tap: if already done → uncheck; else open timer
                          onTap: () => _checked.contains(i)
                              ? _uncheck(i)
                              : _openTimer(i),
                        ),
                      ),
              ),

              // Footer
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: widget.color.withOpacity(0.3), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _allDone
                            ? () => Navigator.pop(context)
                            : _markAllDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _allDone ? 'Done 🎉' : 'Mark all done',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Confetti overlay
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(
                        progress: _confettiCtrl.value, color: widget.color),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  RITUAL TILE
// ─────────────────────────────────────────────────────────
class _RitualTile extends StatelessWidget {
  final Map<String, String> ritual;
  final bool isDone;
  final Color color;
  final VoidCallback onTap;

  const _RitualTile({
    required this.ritual,
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDone ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? color.withOpacity(0.35) : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Checkbox indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isDone ? color : color.withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            // Emoji
            Text(ritual['e'] ?? '', style: const TextStyle(fontSize: 26)),

            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ritual['t'] ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDone ? color : AppColors.textDark,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: color.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone ? 'Tap to undo' : ritual['s'] ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isDone ? color.withOpacity(0.5) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right badge
            isDone
                ? Icon(Icons.check_circle_rounded,
                    size: 22, color: color.withOpacity(0.7))
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 12, color: color),
                        const SizedBox(width: 2),
                        Text(
                          ritual['dur'] ?? '',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TIMER SHEET
//  - Shows ritual detail + circular countdown timer
//  - Auto-completes when timer hits 0
//  - User can tap "Mark as done" at any time to complete early
// ─────────────────────────────────────────────────────────
class _TimerSheet extends StatefulWidget {
  final Map<String, String> ritual;
  final Color color;
  final VoidCallback onComplete;

  const _TimerSheet({
    required this.ritual,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  late int _totalSec;
  late int _remainingSec;
  Timer? _timer;
  bool _running = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _totalSec = _parseDuration(widget.ritual['dur'] ?? '');
    _remainingSec = _totalSec;
    // Auto-start if there's a valid duration
    if (_totalSec > 0) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Parse "15 min", "5 min", "2 min", "30s" etc.
  int _parseDuration(String dur) {
    final mins = RegExp(r'(\d+)\s*min').firstMatch(dur);
    if (mins != null) return int.parse(mins.group(1)!) * 60;
    final secs = RegExp(r'(\d+)\s*s\b').firstMatch(dur);
    if (secs != null) return int.parse(secs.group(1)!);
    return 0; // "All day", "Daily", "Ongoing" → no timer
  }

  void _startTimer() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingSec > 1) {
        setState(() => _remainingSec--);
      } else {
        t.cancel();
        setState(() {
          _remainingSec = 0;
          _running = false;
          _completed = true;
        });
        // Brief pause so user sees ✓, then auto-complete
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resumeTimer() => _startTimer();

  String _formatTime(int sec) {
    if (sec <= 0) return '✓';
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
  }

  double get _progress =>
      _totalSec == 0 ? 1.0 : 1.0 - (_remainingSec / _totalSec);

  Color get _bgColor {
    if (widget.color == const Color(0xFF4A70B0)) return const Color(0xFFF4F7FF);
    if (widget.color == const Color(0xFF5A8E6A)) return const Color(0xFFF2FBF5);
    return const Color(0xFFFEF6F0);
  }

  @override
  Widget build(BuildContext context) {
    final hasTimer = _totalSec > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 28),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Emoji
          Text(widget.ritual['e'] ?? '', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 14),

          // Title
          Text(
            widget.ritual['t'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.ritual['s'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Circular timer (only when duration is parseable)
          if (hasTimer) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, val, __) => CircularProgressIndicator(
                      value: val,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      backgroundColor: widget.color.withOpacity(0.1),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSec),
                      style: GoogleFonts.nunito(
                        fontSize: _completed ? 30 : 38,
                        fontWeight: FontWeight.w900,
                        color: widget.color,
                      ),
                    ),
                    if (!_completed && _totalSec > 0)
                      Text(
                        _running ? 'running' : 'paused',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.color.withOpacity(0.55),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pause / Resume toggle (only while timer not finished)
            if (!_completed)
              TextButton.icon(
                onPressed: _running ? _pauseTimer : _resumeTimer,
                icon: Icon(
                  _running
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 18,
                  color: widget.color.withOpacity(0.7),
                ),
                label: Text(
                  _running ? 'Pause timer' : 'Resume timer',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.color.withOpacity(0.7),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ] else ...[
            // No timer — just a spacer
            const SizedBox(height: 16),
          ],

          // ── Mark as done (always visible, completes immediately) ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completed ? null : widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _completed ? widget.color.withOpacity(0.4) : widget.color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                _completed ? 'Completed ✓' : 'Mark as done',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  CONFETTI PAINTER
// ─────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;

  static List<_Particle>? _particles;

  _ConfettiPainter({required this.progress, required this.color}) {
    if (_particles == null || progress < 0.02) {
      _particles = List.generate(70, (_) => _Particle(Random()));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles!) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.startX * size.width + p.vx * t * size.width * 0.45;
      final y = p.startY * size.height -
          p.vy * t * size.height * 0.65 +
          0.5 * 9.8 * t * t * size.height * 0.38;

      final opacity = (t < 0.15
              ? t / 0.15
              : t > 0.72
                  ? 1.0 - ((t - 0.72) / 0.28)
                  : 1.0)
          .clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * p.rotSpeed * 2 * pi);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  late final double startX, startY, vx, vy;
  late final double size, rotation, rotSpeed, delay;
  late final Color color;
  late final bool isCircle;

  static const _palette = [
    Color(0xFFFF6B9D),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF6348),
    Color(0xFFA29BFE),
    Color(0xFFFF7675),
    Color(0xFF00CEC9),
    Color(0xFFFDCB6E),
    Color(0xFFE17055),
  ];

  _Particle(Random rng) {
    startX = 0.15 + rng.nextDouble() * 0.70;
    startY = 0.45 + rng.nextDouble() * 0.35;
    vx = (rng.nextDouble() - 0.5) * 1.8;
    vy = 0.5 + rng.nextDouble() * 0.9;
    size = 6.0 + rng.nextDouble() * 9.0;
    rotation = rng.nextDouble() * 2 * pi;
    rotSpeed = (rng.nextDouble() - 0.5) * 5;
    delay = rng.nextDouble() * 0.3;
    isCircle = rng.nextBool();
    color = _palette[rng.nextInt(_palette.length)];
  }
}
