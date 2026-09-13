import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main()');
});

final settingsProvider = NotifierProvider<SettingsNotifier, SrsSettings>(SettingsNotifier.new);

class SrsSettings {
  final int dailyNewLimit;
  final int dailyReviewLimit;

  SrsSettings({
    required this.dailyNewLimit,
    required this.dailyReviewLimit,
  });

  SrsSettings copyWith({
    int? dailyNewLimit,
    int? dailyReviewLimit,
  }) {
    return SrsSettings(
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
    );
  }
}

class SettingsNotifier extends Notifier<SrsSettings> {
  @override
  SrsSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SrsSettings(
      dailyNewLimit: prefs.getInt('daily_new_limit') ?? 20,
      dailyReviewLimit: prefs.getInt('daily_review_limit') ?? 200,
    );
  }

  Future<void> updateLimits({int? newLimit, int? reviewLimit}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (newLimit != null) await prefs.setInt('daily_new_limit', newLimit);
    if (reviewLimit != null) await prefs.setInt('daily_review_limit', reviewLimit);

    state = state.copyWith(
      dailyNewLimit: newLimit,
      dailyReviewLimit: reviewLimit,
    );
  }
}
