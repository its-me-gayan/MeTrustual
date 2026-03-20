import '../providers/insights_provider.dart';

/// Centralized configuration for mode-specific titles and subtitles in the Insights screen.
class InsightsModeConfig {
  final String mode;
  final String title;
  final String Function(InsightsData data) subtitle;

  const InsightsModeConfig({
    required this.mode,
    required this.title,
    required this.subtitle,
  });

  /// Factory constructor to create mode-specific configs
  factory InsightsModeConfig.fromMode(String mode) {
    switch (mode) {
      case 'preg':
        return InsightsModeConfig(
          mode: 'preg',
          title: 'Your Journey 💙',
          subtitle: (_) => 'Week 24 of 40',
        );
      case 'ovul':
        return InsightsModeConfig(
          mode: 'ovul',
          title: 'Your Fertility 🌿',
          subtitle: (data) => '${data.cyclesTracked} cycles tracked',
        );
      default: // 'period'
        return InsightsModeConfig(
          mode: 'period',
          title: 'Your Story ✨',
          subtitle: (data) => '${data.cyclesTracked} months of data',
        );
    }
  }
}
