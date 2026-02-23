import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;
  final Color modeColor; // passed from EducationScreen

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.modeColor,
  });

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  // Parse **bold** inline markdown into TextSpans for a single line
  List<TextSpan> _parseInline(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
            TextSpan(text: text.substring(lastEnd, match.start), style: base));
      }
      spans.add(TextSpan(
          text: match.group(1),
          style: base.copyWith(fontWeight: FontWeight.w900)));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: base));
    }
    return spans;
  }

  // Render full body string — handles ## / ### headings and **bold**
  List<Widget> _buildBodyWidgets(String body, Color tagColor) {
    final lines = body.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      // ### Sub-heading — colored with modeColor
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text(
            line.substring(4).trim(),
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: modeColor,
              height: 1.4,
            ),
          ),
        ));
        continue;
      }

      // ## Section heading — dark text, larger
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 6),
          child: Text(
            line.substring(3).trim(),
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
        ));
        continue;
      }

      // Empty line → small gap
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Normal paragraph with inline **bold** support
      final baseStyle = GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.65,
      );
      widgets.add(RichText(
        text: TextSpan(children: _parseInline(line, baseStyle)),
      ));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _getColorFromHex(article['tag_color'] ?? '#F7A8B8');
    final tagLabel = (article['tag_label'] ?? 'Info').toString().toUpperCase();
    final title = article['title'] ?? 'Untitled';
    final icon = article['icon'] ?? '📖';
    final body = article['body'] ?? '';
    final duration = article['duration'] ?? '';
    final isPremium = article['isPremium'] == true;
    final keyPoints = article['keyPoints'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.textDark),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      modeColor.withOpacity(0.15), // hero tinted by mode
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: modeColor.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: modeColor.withOpacity(0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(icon, style: const TextStyle(fontSize: 36)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag + premium badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tagLabel,
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: tagColor),
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('✨ PREMIUM',
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                      ],
                      const Spacer(),
                      if (duration.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(duration,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.3),
                  ),
                  const SizedBox(height: 20),

                  // Divider tinted with modeColor
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        modeColor.withOpacity(0.4),
                        AppColors.border.withOpacity(0.3),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Key Points card tinted with modeColor
                  if (keyPoints.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: modeColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: modeColor.withOpacity(0.18), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('Key Takeaways',
                                  style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textDark)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...keyPoints.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                          color: modeColor,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        point.toString(),
                                        style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                            height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Body text — ## / ### / **bold**
                  if (body.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildBodyWidgets(body, tagColor),
                    ),

                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: Text(
                      '🌸 Stay informed, stay empowered',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: modeColor.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
