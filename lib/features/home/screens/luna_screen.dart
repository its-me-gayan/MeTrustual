import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';

// ─────────────────────────────────────────────────────────────
//  MODE THEME
//  Mirrors the HTML prototype's data-mode CSS selectors exactly.
//  Every color token below maps 1:1 to a CSS value in the HTML.
// ─────────────────────────────────────────────────────────────

class _ModeTheme {
  // overlay background gradient
  final List<Color> overlayBg;
  // header
  final Color headerBorder;
  final Color headerBg;
  // close / back button
  final Color closeBorder;
  final Color closeColor;
  final Color closeHover;
  // moon avatar
  final List<Color> avatarGradient;
  final Color avatarBorder;
  // "Ask Soluna" em accent
  final Color accentName;
  // usage bar
  final Color usageBorder;
  final Color usageCountColor;
  // usage dots
  final List<Color> dotUsed;
  final Color dotShadow;
  // upgrade chip
  final Color upgradeBg;
  final Color upgradeColor;
  final Color upgradeBorder;
  // Luna reply bubble
  final Color bubbleLunaBorder;
  // User message bubble
  final List<Color> bubbleUser;
  final Color bubbleUserShadow;
  // avatar in message row
  final List<Color> msgAvatarGradient;
  final Color msgAvatarBorder;
  // typing dots bubble
  final Color typingDotsBorder;
  final Color typingDotColor;
  // suggestion chips
  final Color suggLabel;
  final Color suggBorder;
  final Color suggColor;
  final Color suggHoverBorder;
  final Color suggHoverColor;
  final Color suggHoverBg;
  // input
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color inputFocusShadow;
  // send button
  final List<Color> sendGradient;
  final Color sendShadow;
  // input wrap
  final Color inputWrapBorder;
  final Color inputWrapBg;
  // premium gate
  final List<Color> gateGradient;
  final Color gateBorder;
  final Color gateTitleColor;
  final Color gateSubColor;
  final List<Color> gateBtnGradient;
  final Color gateBtnShadow;
  // disclaimer text
  final Color disclaimerColor;

  const _ModeTheme({
    required this.overlayBg,
    required this.headerBorder,
    required this.headerBg,
    required this.closeBorder,
    required this.closeColor,
    required this.closeHover,
    required this.avatarGradient,
    required this.avatarBorder,
    required this.accentName,
    required this.usageBorder,
    required this.usageCountColor,
    required this.dotUsed,
    required this.dotShadow,
    required this.upgradeBg,
    required this.upgradeColor,
    required this.upgradeBorder,
    required this.bubbleLunaBorder,
    required this.bubbleUser,
    required this.bubbleUserShadow,
    required this.msgAvatarGradient,
    required this.msgAvatarBorder,
    required this.typingDotsBorder,
    required this.typingDotColor,
    required this.suggLabel,
    required this.suggBorder,
    required this.suggColor,
    required this.suggHoverBorder,
    required this.suggHoverColor,
    required this.suggHoverBg,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.inputFocusShadow,
    required this.sendGradient,
    required this.sendShadow,
    required this.inputWrapBorder,
    required this.inputWrapBg,
    required this.gateGradient,
    required this.gateBorder,
    required this.gateTitleColor,
    required this.gateSubColor,
    required this.gateBtnGradient,
    required this.gateBtnShadow,
    required this.disclaimerColor,
  });
}

// ── period / rose (default) ───────────────────────────────────
const _tPeriod = _ModeTheme(
  overlayBg: [
    Color(0xFFFFF8F5),
    Color(0xFFFEF0F5),
    Color(0xFFFCE8F4),
    Color(0xFFF8E8F8)
  ],
  headerBorder: Color(0xFFFCE8E4),
  headerBg: Color(0xB3FFFCFA),
  closeBorder: Color(0xFFFCE8E4),
  closeColor: Color(0xFFC0909A),
  closeHover: Color(0xFFD97B8A),
  avatarGradient: [Color(0xFFFCE0E8), Color(0xFFF0C8D8)],
  avatarBorder: Color(0x40D97B8A),
  accentName: Color(0xFFC95678),
  usageBorder: Color(0xFFFCE8E4),
  usageCountColor: Color(0xFFD97B8A),
  dotUsed: [Color(0xFFF09090), Color(0xFFD97B8A)],
  dotShadow: Color(0x59D97B8A),
  upgradeBg: Color(0xFFFFF0F2),
  upgradeColor: Color(0xFFD97B8A),
  upgradeBorder: Color(0xFFFCD0DA),
  bubbleLunaBorder: Color(0xFFFCE8E4),
  bubbleUser: [Color(0xFFF09090), Color(0xFFD97B8A)],
  bubbleUserShadow: Color(0x4DD97B8A),
  msgAvatarGradient: [Color(0xFFFCE0E8), Color(0xFFF0C8D8)],
  msgAvatarBorder: Color(0x40D97B8A),
  typingDotsBorder: Color(0xFFFCE8E4),
  typingDotColor: Color(0xFFF0B0BC),
  suggLabel: Color(0xFFD0A8B0),
  suggBorder: Color(0xFFFCE8E4),
  suggColor: Color(0xFFC0909A),
  suggHoverBorder: Color(0xFFD97B8A),
  suggHoverColor: Color(0xFFD97B8A),
  suggHoverBg: Color(0xFFFFF5F6),
  inputBorder: Color(0xFFFCE8E4),
  inputFocusBorder: Color(0xFFD97B8A),
  inputFocusShadow: Color(0x1AD97B8A),
  sendGradient: [Color(0xFFF09090), Color(0xFFD97B8A)],
  sendShadow: Color(0x59D97B8A),
  inputWrapBorder: Color(0xFFFCE8E4),
  inputWrapBg: Color(0xCCFFFCFA),
  gateGradient: [Color(0xFFFFF5F0), Color(0xFFFFEEF4)],
  gateBorder: Color(0xFFFCD8E0),
  gateTitleColor: Color(0xFFD97B8A),
  gateSubColor: Color(0xFFC0A0A8),
  gateBtnGradient: [Color(0xFFF09090), Color(0xFFD97B8A)],
  gateBtnShadow: Color(0x59D97B8A),
  disclaimerColor: Color(0xFFD0B0B8),
);

// ── pregnancy / blue ──────────────────────────────────────────
const _tPreg = _ModeTheme(
  overlayBg: [
    Color(0xFFF5F8FF),
    Color(0xFFEEF2FF),
    Color(0xFFE8EEFF),
    Color(0xFFE4EAFF)
  ],
  headerBorder: Color(0xFFB4CDF0),
  headerBg: Color(0xBFF8FBFF),
  closeBorder: Color(0xFFC8D8F4),
  closeColor: Color(0xFF7090C0),
  closeHover: Color(0xFF4A70B0),
  avatarGradient: [Color(0xFFDDE8F8), Color(0xFFC8D8F4)],
  avatarBorder: Color(0x4D4A70B0),
  accentName: Color(0xFF4A70B0),
  usageBorder: Color(0xFFC8D8F4),
  usageCountColor: Color(0xFF4A70B0),
  dotUsed: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
  dotShadow: Color(0x594A70B0),
  upgradeBg: Color(0xFFEEF4FF),
  upgradeColor: Color(0xFF4A70B0),
  upgradeBorder: Color(0xFFB8CCF0),
  bubbleLunaBorder: Color(0xFFC8D8F4),
  bubbleUser: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
  bubbleUserShadow: Color(0x4D4A70B0),
  msgAvatarGradient: [Color(0xFFDDE8F8), Color(0xFFC8D8F4)],
  msgAvatarBorder: Color(0x404A70B0),
  typingDotsBorder: Color(0xFFC8D8F4),
  typingDotColor: Color(0xFF90B0D8),
  suggLabel: Color(0xFF90B0D0),
  suggBorder: Color(0xFFC8D8F4),
  suggColor: Color(0xFF7090B8),
  suggHoverBorder: Color(0xFF4A70B0),
  suggHoverColor: Color(0xFF4A70B0),
  suggHoverBg: Color(0xFFF0F4FF),
  inputBorder: Color(0xFFC8D8F4),
  inputFocusBorder: Color(0xFF4A70B0),
  inputFocusShadow: Color(0x1A4A70B0),
  sendGradient: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
  sendShadow: Color(0x594A70B0),
  inputWrapBorder: Color(0xFFC8D8F4),
  inputWrapBg: Color(0xCCF8FBFF),
  gateGradient: [Color(0xFFF0F4FF), Color(0xFFEAF0FF)],
  gateBorder: Color(0xFFB8CCF0),
  gateTitleColor: Color(0xFF4A70B0),
  gateSubColor: Color(0xFF7090B0),
  gateBtnGradient: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
  gateBtnShadow: Color(0x594A70B0),
  disclaimerColor: Color(0xFFA0B8D0),
);

// ── ovulation / green ─────────────────────────────────────────
const _tOvul = _ModeTheme(
  overlayBg: [
    Color(0xFFF5FFF8),
    Color(0xFFEEFFF4),
    Color(0xFFE8FAF0),
    Color(0xFFE4F8EC)
  ],
  headerBorder: Color(0xFFA0D2B4),
  headerBg: Color(0xBFF8FFFB),
  closeBorder: Color(0xFFB8DCC8),
  closeColor: Color(0xFF6AAE8A),
  closeHover: Color(0xFF5A8E6A),
  avatarGradient: [Color(0xFFD4EEDD), Color(0xFFBFDFCC)],
  avatarBorder: Color(0x4D5A8E6A),
  accentName: Color(0xFF5A8E6A),
  usageBorder: Color(0xFFB8DCC8),
  usageCountColor: Color(0xFF5A8E6A),
  dotUsed: [Color(0xFF78C890), Color(0xFF5A8E6A)],
  dotShadow: Color(0x595A8E6A),
  upgradeBg: Color(0xFFEEFFEE),
  upgradeColor: Color(0xFF5A8E6A),
  upgradeBorder: Color(0xFFA8D8B8),
  bubbleLunaBorder: Color(0xFFB8DCC8),
  bubbleUser: [Color(0xFF78C890), Color(0xFF5A8E6A)],
  bubbleUserShadow: Color(0x4D5A8E6A),
  msgAvatarGradient: [Color(0xFFD4EEDD), Color(0xFFBFDFCC)],
  msgAvatarBorder: Color(0x405A8E6A),
  typingDotsBorder: Color(0xFFB8DCC8),
  typingDotColor: Color(0xFF80C898),
  suggLabel: Color(0xFF90C0A0),
  suggBorder: Color(0xFFB8DCC8),
  suggColor: Color(0xFF6AAE8A),
  suggHoverBorder: Color(0xFF5A8E6A),
  suggHoverColor: Color(0xFF5A8E6A),
  suggHoverBg: Color(0xFFF0FAF4),
  inputBorder: Color(0xFFB8DCC8),
  inputFocusBorder: Color(0xFF5A8E6A),
  inputFocusShadow: Color(0x1A5A8E6A),
  sendGradient: [Color(0xFF78C890), Color(0xFF5A8E6A)],
  sendShadow: Color(0x595A8E6A),
  inputWrapBorder: Color(0xFFB8DCC8),
  inputWrapBg: Color(0xCCF8FFFB),
  gateGradient: [Color(0xFFF0FFF4), Color(0xFFEAFFF0)],
  gateBorder: Color(0xFFA8D8B8),
  gateTitleColor: Color(0xFF5A8E6A),
  gateSubColor: Color(0xFF7AAE8A),
  gateBtnGradient: [Color(0xFF78C890), Color(0xFF5A8E6A)],
  gateBtnShadow: Color(0x595A8E6A),
  disclaimerColor: Color(0xFF90B8A0),
);

_ModeTheme _themeFor(String mode) {
  if (mode == 'preg') return _tPreg;
  if (mode == 'ovul') return _tOvul;
  return _tPeriod;
}

// ─────────────────────────────────────────────────────────────
//  SUGGESTIONS  — matches HTML LUNA_SUGGESTIONS
// ─────────────────────────────────────────────────────────────

const _suggs = {
  'period': [
    'Why do I feel so anxious before my period?',
    'What does fertile cervical mucus look like?',
    'How can I ease period cramps naturally?',
    'Why is my cycle changing in length?',
    "What's the luteal phase and why does it matter?",
  ],
  'preg': [
    'My back has been hurting at 24 weeks — normal?',
    'What should I feel by week 24?',
    'How often should I feel kicks?',
    "What's safe to eat in the second trimester?",
    'Signs I should call my OB right away?',
  ],
  'ovul': [
    "My BBT didn't rise — did I miss ovulation?",
    'What does a positive OPK mean?',
    "How do I know if I'm in my fertile window?",
    'Can stress delay ovulation?',
    "What's the best time to try to conceive?",
  ],
};

// ─────────────────────────────────────────────────────────────
//  MESSAGE MODEL
// ─────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isLuna;
  final DateTime time;
  final bool showDisclaimer;
  final bool isError;
  const _Msg({
    required this.text,
    required this.isLuna,
    required this.time,
    this.showDisclaimer = false,
    this.isError = false,
  });
}

const _freeLimit = 3;

// ─────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────

class LunaScreen extends ConsumerStatefulWidget {
  const LunaScreen({super.key});

  @override
  ConsumerState<LunaScreen> createState() => _LunaScreenState();
}

class _LunaScreenState extends ConsumerState<LunaScreen> {
  final List<_Msg> _msgs = [];
  bool _thinking = false;
  bool _initing = true;
  bool _showSugg = true;
  int _used = 0;
  String? _apiKey;

  Timer? _dotTimer;
  int _dotCount = 1;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── init ─────────────────────────────────────────────────────
  Future<void> _init() async {
    await Future.wait([_loadCount(), _loadKey()]);
    if (!mounted) return;
    setState(() => _initing = false);
    _addWelcome();
  }

  // ── daily limit ──────────────────────────────────────────────
  Future<void> _loadCount() async {
    final p = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if ((p.getString('luna_date') ?? '') != today) {
      await p.setString('luna_date', today);
      await p.setInt('luna_count', 0);
    }
    _used = p.getInt('luna_count') ?? 0;
  }

  Future<void> _incCount() async {
    _used++;
    final p = await SharedPreferences.getInstance();
    await p.setInt('luna_count', _used);
  }

  bool get _atLimit => _used >= _freeLimit;
  int get _remaining => (_freeLimit - _used).clamp(0, _freeLimit);

  // ── API key from Firestore ───────────────────────────────────
  Future<void> _loadKey() async {
    try {
      final doc = await ref
          .read(firestoreProvider)
          .collection('config')
          .doc('anthropic')
          .get();
      _apiKey = doc.data()?['apiKey'] as String?;
    } catch (_) {}
  }

  // ── welcome message ──────────────────────────────────────────
  void _addWelcome() {
    final mode = ref.read(modeProvider);
    // matches lunaAddWelcome() in the HTML
    final text = switch (mode) {
      'period' =>
        "Hi lovely 💕\n\nI'm Soluna — your cycle companion. I'm here to help you understand your body, your patterns, and how you're feeling.\n\nYou're on cycle day 14 today — right in your fertile window! Ask me anything on your mind ✨",
      'preg' =>
        "Hi lovely 💕\n\nI'm Soluna — here with you every step of your pregnancy. Congratulations on week 24! You're doing wonderfully.\n\nBaby is growing fast and you're more than halfway there. I'm here for any questions 💙",
      'ovul' =>
        "Hi lovely 💕\n\nI'm Soluna — your fertility companion. Today looks like your peak fertile day — exciting! 🎯\n\nI'm here to help you understand your charts, symptoms, and anything else on your mind 🌿",
      _ => "Hi lovely 💕\n\nI'm Soluna — here to help. What's on your mind? 🌙",
    };
    setState(
        () => _msgs.add(_Msg(text: text, isLuna: true, time: DateTime.now())));
  }

  // ── system prompt ────────────────────────────────────────────
  String _systemPrompt(String mode, String logCtx) {
    final ctx = switch (mode) {
      'period' =>
        'The user is tracking their menstrual cycle. They are on cycle day 14, in their fertile window. Average cycle 28 days, 5-day period. Next period: March 6.',
      'preg' =>
        'The user is pregnant at week 24 (2nd trimester). Due date: June 5. Baby ~600g. Logged: fatigue, back pain, heartburn. Next appointment: March 3.',
      'ovul' =>
        'The user tracks ovulation. Today is predicted peak fertile day (cycle day 14). OPK high, BBT 36.72°C, confidence 89%.',
      _ => '',
    };
    return '''You are Soluna ✨, the AI health companion built into the Soluna app. You're emotionally supportive, medically careful, and always feel like a knowledgeable best friend — never cold or clinical.

Current user context:
- Mode: ${mode == 'preg' ? 'Pregnancy Tracker' : mode == 'ovul' ? 'Ovulation Tracker' : 'Period Tracker'}
- $ctx
- $logCtx

Your style:
- Warm, validating, never dismissive
- Give real, helpful information — don't hedge everything
- Always disclaim you're not a doctor for any medical concern: end with "I'm not a doctor though — if this persists, definitely mention it to yours 💕"
- Keep responses concise and conversational (2–4 short paragraphs max)
- Use line breaks generously for readability
- Use occasional soft emoji (🌙 💕 🌿 ✨) — never excessive
- Never be robotic. You have warmth and personality.''';
  }

  Future<String> _buildLogCtx(String mode) async {
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return 'No log data available.';
      final snap = await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(uid)
          .collection('logs')
          .doc(mode)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(7)
          .get();
      if (snap.docs.isEmpty) return 'User has no recent logs yet.';
      final sb = StringBuffer('Recent logs:\n');
      for (final d in snap.docs) {
        final data = d.data();
        final s = (data['symptoms'] as List?)?.join(', ') ?? 'none';
        sb.writeln('• ${data['date']}: mood=${data['mood']}, symptoms=[$s]');
      }
      return sb.toString();
    } catch (_) {
      return 'Could not retrieve log data.';
    }
  }

  // ── send ─────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _thinking) return;
    if (_atLimit) {
      _showGateSheet();
      return;
    }

    _inputCtrl.clear();
    setState(() {
      _showSugg = false;
      _msgs.add(_Msg(text: text, isLuna: false, time: DateTime.now()));
      _thinking = true;
      _dotCount = 1;
    });
    _scrollBottom();
    _startDots();
    await _incCount();

    try {
      final mode = ref.read(modeProvider);
      final logCtx = await _buildLogCtx(mode);
      final reply = await _callApi(text, _systemPrompt(mode, logCtx));
      _stopDots();
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _msgs.add(_Msg(
            text: reply,
            isLuna: true,
            time: DateTime.now(),
            showDisclaimer: true));
      });
    } catch (_) {
      _stopDots();
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _msgs.add(_Msg(
            text: "I lost my connection for a second — sorry! Try again? 🌙",
            isLuna: true,
            time: DateTime.now(),
            isError: true));
      });
    }

    _scrollBottom();

    // show gate 800ms after last free message (matches HTML setTimeout)
    if (_atLimit) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() {});
    }
  }

  Future<String> _callApi(String msg, String system) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'No API key — add config/anthropic → apiKey in Firestore.');
    }
    final history = _msgs.skip(1).where((m) => !m.isError).toList();
    final recent =
        history.length > 6 ? history.sublist(history.length - 6) : history;
    final messages = [
      ...recent.map((m) => {
            'role': m.isLuna ? 'assistant' : 'user',
            'content': m.text,
          }),
      {'role': 'user', 'content': msg},
    ];

    final res = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey!,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-sonnet-4-5',
            'max_tokens': 1000,
            'system': system,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) throw Exception('API ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final content = json['content'] as List?;
    if (content == null || content.isEmpty) throw Exception('Empty response');
    return (content.first as Map)['text'] as String? ?? '';
  }

  // ── dots ─────────────────────────────────────────────────────
  void _startDots() {
    _dotTimer?.cancel();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted)
        setState(() => _dotCount = _dotCount == 3 ? 1 : _dotCount + 1);
    });
  }

  void _stopDots() {
    _dotTimer?.cancel();
    _dotTimer = null;
  }

  // ── scroll ───────────────────────────────────────────────────
  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── gate sheet ───────────────────────────────────────────────
  void _showGateSheet() {
    final t = _themeFor(ref.read(modeProvider));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GateSheet(
        t: t,
        onUpgrade: () {
          Navigator.pop(context);
          context.go('/premium');
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final t = _themeFor(mode);

    if (_initing) {
      return Scaffold(
        backgroundColor: t.overlayBg.first,
        body: Center(
            child: CircularProgressIndicator(
                color: t.sendGradient.last, strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      body: Container(
        // .luna-overlay background — warm cream for period, blue-tint for preg, green-tint for ovul
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: t.overlayBg,
            stops: const [0.0, 0.45, 0.80, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildHeader(mode, t),
            _buildUsageBar(t),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: _buildMsgList(t),
              ),
            ),
            // inline gate appears after last free message
            if (_atLimit) _buildGateInline(t),
            // suggestions shown until first user message
            if (_showSugg && _msgs.length <= 1) _buildSuggestions(mode, t),
            _buildInputBar(t),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HEADER — .luna-header
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(String mode, _ModeTheme t) {
    final modeLabel = switch (mode) {
      'period' => 'Cycle Tracker 🌸',
      'preg' => 'Pregnancy 💙',
      'ovul' => 'Ovulation Tracker 🌿',
      _ => 'Health Companion',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(
        color: t.headerBg,
        border: Border(bottom: BorderSide(color: t.headerBorder, width: 1.5)),
      ),
      child: Row(children: [
        // ← .luna-close
        _CloseButton(
          borderColor: t.closeBorder,
          color: t.closeColor,
          hoverColor: t.closeHover,
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        const SizedBox(width: 8),

        // 🌙 .luna-avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: t.avatarGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: t.avatarBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: t.avatarBorder,
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child:
              const Center(child: Text('🌙', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // .luna-header-name  "Ask <em>Soluna</em> 🌙"
              Row(children: [
                Text('Ask ',
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3D2828))),
                Text('Soluna',
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: t.accentName)), // em color changes per mode
                Text(' 🌙',
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3D2828))),
              ]),
              // .luna-status — "Here for you" with green dot
              Row(children: [
                Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF7DC880))),
                Text('Here for you',
                    style: GoogleFonts.nunito(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA0B890))),
              ]),
              // mode label
              Text(modeLabel,
                  style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: t.accentName)),
            ],
          ),
        ),

        // "Online" pill — always green
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF5A8E6A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF5A8E6A).withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF5A8E6A))),
            const SizedBox(width: 5),
            Text('Online',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A8E6A))),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  USAGE BAR — .luna-usage-bar
  // ─────────────────────────────────────────────────────────────

  Widget _buildUsageBar(_ModeTheme t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.usageBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: t.usageBorder.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // "Free: X messages today"
          Text('Free: ',
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC0A0A8))),
          Text('$_remaining',
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: t.usageCountColor)),
          Text(' messages today',
              style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC0A0A8))),

          const Spacer(),

          // dots  (.luna-dot / .luna-dot.used)
          ...List.generate(
              _freeLimit,
              (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i < _remaining
                          ? LinearGradient(colors: t.dotUsed)
                          : null,
                      color: i < _remaining ? null : const Color(0xFFFCE8E4),
                      boxShadow: i < _remaining
                          ? [BoxShadow(color: t.dotShadow, blurRadius: 5)]
                          : null,
                    ),
                  )),

          const SizedBox(width: 8),

          // ✨ Unlimited chip
          GestureDetector(
            onTap: _showGateSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: t.upgradeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.upgradeBorder, width: 1.5),
              ),
              child: Text('✨ Unlimited',
                  style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: t.upgradeColor)),
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  MESSAGE LIST
  // ─────────────────────────────────────────────────────────────

  Widget _buildMsgList(_ModeTheme t) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      itemCount: _msgs.length + (_thinking ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _msgs.length) return _buildTyping(t);
        return _buildBubble(_msgs[i], t);
      },
    );
  }

  // ── message bubble — .luna-msg / .luna-bubble ─────────────────
  Widget _buildBubble(_Msg msg, _ModeTheme t) {
    final isLuna = msg.isLuna;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isLuna ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🌙 avatar left for Luna — .luna-msg-avatar
          if (isLuna)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: t.msgAvatarGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                border: Border.all(color: t.msgAvatarBorder, width: 1.5),
              ),
              child: const Center(
                  child: Text('🌙', style: TextStyle(fontSize: 13))),
            ),

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isLuna ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // .luna-bubble.luna  OR  .luna-bubble.user
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    // Luna reply = white card with colored border
                    // User msg = colored gradient, no border
                    color: isLuna
                        ? (msg.isError ? const Color(0xFFFFF0F0) : Colors.white)
                        : null,
                    gradient: isLuna
                        ? null
                        : LinearGradient(
                            colors: t.bubbleUser,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      // bottom-left:4 for Luna, bottom-right:4 for user
                      bottomLeft: Radius.circular(isLuna ? 4 : 18),
                      bottomRight: Radius.circular(isLuna ? 18 : 4),
                    ),
                    border: isLuna
                        ? Border.all(
                            color: msg.isError
                                ? const Color(0xFFF0B0B8)
                                : t.bubbleLunaBorder,
                            width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: isLuna
                              ? t.bubbleLunaBorder.withOpacity(0.3)
                              : t.bubbleUserShadow,
                          blurRadius: isLuna ? 10 : 14,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(msg.text,
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          // .luna-bubble.luna: #3d2828
                          // .luna-bubble.user: white
                          color:
                              isLuna ? const Color(0xFF3D2828) : Colors.white,
                          height: 1.65)),
                ),

                // .luna-disclaimer
                if (isLuna && msg.showDisclaimer)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 2),
                    child: Text(
                        '🔒 Not medical advice · Always consult your doctor',
                        style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: t.disclaimerColor)),
                  ),
              ],
            ),
          ),
          if (!isLuna) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── typing indicator — .luna-typing / .luna-typing-dots ──────
  Widget _buildTyping(_ModeTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 8, bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: t.msgAvatarGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: t.msgAvatarBorder, width: 1.5),
          ),
          child:
              const Center(child: Text('🌙', style: TextStyle(fontSize: 13))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18)),
            border: Border.all(color: t.typingDotsBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: t.typingDotsBorder.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                3,
                (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _dotCount
                              ? t.typingDotColor
                              : t.typingDotColor.withOpacity(0.25)),
                    )),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  INLINE GATE — .luna-gate
  // ─────────────────────────────────────────────────────────────

  Widget _buildGateInline(_ModeTheme t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: t.gateGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.gateBorder, width: 1.5),
      ),
      child: Column(children: [
        Text("✨ You've used your 3 free messages today",
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: t.gateTitleColor)),
        const SizedBox(height: 4),
        Text(
            'Upgrade to Soluna Premium for unlimited chats,\nplus advanced insights, BBT analysis & more 🌙',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: t.gateSubColor,
                height: 1.5)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showGateSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.gateBtnGradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: t.gateBtnShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Center(
                child: Text('Upgrade to Premium · \$4.99/mo',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SUGGESTIONS — .luna-suggestions / .luna-sugg
  // ─────────────────────────────────────────────────────────────

  Widget _buildSuggestions(String mode, _ModeTheme t) {
    final chips = _suggs[mode] ?? _suggs['period']!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ASK ME ANYTHING',
            style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: t.suggLabel,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map((s) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _SuggChip(
                        label: s,
                        t: t,
                        onTap: () {
                          _inputCtrl.text = s;
                          _send();
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  INPUT BAR — .luna-input-wrap / .luna-input / .luna-send
  // ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(_ModeTheme t) {
    final bottomPad =
        MediaQuery.of(context).viewInsets.bottom > 0 ? 10.0 : 18.0;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPad),
      decoration: BoxDecoration(
        color: t.inputWrapBg,
        border: Border(top: BorderSide(color: t.inputWrapBorder, width: 1.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // .luna-input
        Expanded(
          child: _InputField(
            controller: _inputCtrl,
            focusNode: _focusNode,
            disabled: _atLimit || _thinking,
            borderColor: t.inputBorder,
            focusBorderColor: t.inputFocusBorder,
            focusShadowColor: t.inputFocusShadow,
            placeholder: _atLimit
                ? 'Upgrade to keep chatting 🌙'
                : 'Ask Soluna anything…',
            onSubmit: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),

        // .luna-send — circle with ↑
        GestureDetector(
          onTap: (_atLimit || _thinking) ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: (_atLimit || _thinking)
                  ? const LinearGradient(
                      colors: [Color(0xFFE0D0D0), Color(0xFFE0D0D0)])
                  : LinearGradient(
                      colors: t.sendGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
              boxShadow: (_atLimit || _thinking)
                  ? []
                  : [
                      BoxShadow(
                          color: t.sendShadow,
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                    ],
            ),
            child: Center(
                child: Text('↑',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: (_atLimit || _thinking)
                            ? const Color(0xFFB0A0A0)
                            : Colors.white))),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CLOSE BUTTON  — .luna-close
// ─────────────────────────────────────────────────────────────

class _CloseButton extends StatefulWidget {
  final Color borderColor, color, hoverColor;
  final VoidCallback onTap;
  const _CloseButton({
    required this.borderColor,
    required this.color,
    required this.hoverColor,
    required this.onTap,
  });
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
                color: _hover ? widget.hoverColor : widget.borderColor,
                width: 1.5),
          ),
          child: Center(
              child: Text('←',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _hover ? widget.hoverColor : widget.color))),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUGGESTION CHIP  — .luna-sugg
// ─────────────────────────────────────────────────────────────

class _SuggChip extends StatefulWidget {
  final String label;
  final _ModeTheme t;
  final VoidCallback onTap;
  const _SuggChip({required this.label, required this.t, required this.onTap});
  @override
  State<_SuggChip> createState() => _SuggChipState();
}

class _SuggChipState extends State<_SuggChip> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _hover ? t.suggHoverBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _hover ? t.suggHoverBorder : t.suggBorder, width: 1.5),
          ),
          child: Text(widget.label,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _hover ? t.suggHoverColor : t.suggColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INPUT FIELD  — .luna-input
// ─────────────────────────────────────────────────────────────

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final Color borderColor, focusBorderColor, focusShadowColor;
  final String placeholder;
  final ValueChanged<String> onSubmit;
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.borderColor,
    required this.focusBorderColor,
    required this.focusShadowColor,
    required this.placeholder,
    required this.onSubmit,
  });
  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(
        () => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.disabled ? const Color(0xFFFDF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: _focused ? widget.focusBorderColor : widget.borderColor,
            width: 1.5),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: widget.focusShadowColor,
                    blurRadius: 0,
                    spreadRadius: 3)
              ]
            : [
                BoxShadow(
                    color: widget.borderColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: !widget.disabled,
        maxLines: 4,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D2828)),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDDBEC0)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onSubmitted: widget.disabled ? null : widget.onSubmit,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PREMIUM GATE SHEET  — matches HTML limit sheet
// ─────────────────────────────────────────────────────────────

class _GateSheet extends StatelessWidget {
  final _ModeTheme t;
  final VoidCallback onUpgrade;
  const _GateSheet({required this.t, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: t.gateBtnShadow.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // handle
        Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: const Color(0xFFE0C0C4),
                borderRadius: BorderRadius.circular(2))),

        // 🌙 moon icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                t.sendGradient.last.withOpacity(0.2),
                t.sendGradient.last.withOpacity(0.05),
              ]),
              border: Border.all(
                  color: t.sendGradient.last.withOpacity(0.3), width: 1.5)),
          child:
              const Center(child: Text('🌙', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 16),

        Text('Soluna misses you ✨',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF3D2828))),
        const SizedBox(height: 8),
        Text(
            "You've used your 3 free messages for today.\nUpgrade to chat with Soluna as much as you need.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB09090),
                height: 1.55)),
        const SizedBox(height: 20),

        // perks
        ...[
          ('💬', 'Unlimited Soluna messages, every day'),
          ('📊', 'AI-powered weekly health insights'),
          ('🎯', 'Personalised phase tips & predictions'),
        ].map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(p.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(p.$2,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A3838))),
              ]),
            )),

        const SizedBox(height: 20),

        // CTA — gradient matches current mode
        GestureDetector(
          onTap: onUpgrade,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.gateBtnGradient),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: t.gateBtnShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Center(
                child: Text('Unlock Premium ✨',
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ),
        ),
        const SizedBox(height: 10),

        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe tomorrow',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB09090)))),
      ]),
    );
  }
}
