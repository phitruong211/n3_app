import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/database.dart';
import '../data/srs_service.dart';
import 'core_providers.dart';
import 'settings_provider.dart';

final deckStatsProvider = StreamProvider.family<DeckStats, String>((ref, deckId) {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.cards)..where((c) => c.deckId.equals(deckId));
  
  return query.watch().map((cards) {
    int total = cards.length;
    int learning = 0;
    int review = 0;
    int relearning = 0;
    int newCards = 0;
    
    for (var card in cards) {
      if (card.state == CardState.newCard.index) newCards++;
      else if (card.state == CardState.learning.index) learning++;
      else if (card.state == CardState.review.index) review++;
      else if (card.state == CardState.relearning.index) relearning++;
    }
    
    return DeckStats(
      total: total,
      newCards: newCards,
      learning: learning,
      review: review,
      relearning: relearning,
    );
  });
});

class DeckStats {
  final int total;
  final int newCards;
  final int learning;
  final int review;
  final int relearning;

  DeckStats({
    required this.total,
    required this.newCards,
    required this.learning,
    required this.review,
    required this.relearning,
  });
}

// Manages daily counters
final dailyCountersProvider = NotifierProvider<DailyCountersNotifier, DailyCounters>(DailyCountersNotifier.new);

class DailyCounters {
  final int newStudied;
  final int reviewStudied;

  DailyCounters({this.newStudied = 0, this.reviewStudied = 0});
}

class DailyCountersNotifier extends Notifier<DailyCounters> {
  @override
  DailyCounters build() {
    return _loadAndCheckReset();
  }
  
  DailyCounters _loadAndCheckReset() {
    final prefs = ref.read(sharedPreferencesProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString('last_study_date');
    
    if (savedDate != todayStr) {
      prefs.setString('last_study_date', todayStr);
      prefs.setInt('today_new_studied', 0);
      prefs.setInt('today_review_studied', 0);
      return DailyCounters(newStudied: 0, reviewStudied: 0);
    } else {
      return DailyCounters(
        newStudied: prefs.getInt('today_new_studied') ?? 0,
        reviewStudied: prefs.getInt('today_review_studied') ?? 0,
      );
    }
  }

  void incrementNew() {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = state.newStudied + 1;
    prefs.setInt('today_new_studied', val);
    state = DailyCounters(newStudied: val, reviewStudied: state.reviewStudied);
  }

  void incrementReview() {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = state.reviewStudied + 1;
    prefs.setInt('today_review_studied', val);
    state = DailyCounters(newStudied: state.newStudied, reviewStudied: val);
  }
}

// Fetch Due Cards for a Deck
final dueCardsProvider = FutureProvider.family<List<Card>, String?>((ref, deckId) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsProvider);
  final counters = ref.watch(dailyCountersProvider);
  
  final newLimit = settings.dailyNewLimit - counters.newStudied;
  final reviewLimit = settings.dailyReviewLimit - counters.reviewStudied;
  
  final now = DateTime.now();

  // Query Learning & Relearning (bypasses limits usually)
  final learningQuery = db.select(db.cards)
    ..where((c) {
      var condition = c.state.equals(CardState.learning.index) | c.state.equals(CardState.relearning.index);
      condition = condition & (c.due.isNull() | c.due.isSmallerOrEqualValue(now));
      if (deckId != null) condition = condition & c.deckId.equals(deckId);
      return condition;
    })
    ..orderBy([(c) => OrderingTerm(expression: c.due, mode: OrderingMode.asc)]);
  
  final learningCards = await learningQuery.get();

  // Query Reviews
  List<Card> reviewCards = [];
  if (reviewLimit > 0) {
    final reviewQuery = db.select(db.cards)
      ..where((c) {
        var condition = c.state.equals(CardState.review.index);
        condition = condition & (c.due.isNull() | c.due.isSmallerOrEqualValue(now));
        if (deckId != null) condition = condition & c.deckId.equals(deckId);
        return condition;
      })
      ..orderBy([(c) => OrderingTerm(expression: c.due, mode: OrderingMode.asc)])
      ..limit(reviewLimit);
    reviewCards = await reviewQuery.get();
  }

  // Query New Cards
  List<Card> newCards = [];
  if (newLimit > 0) {
    final newQuery = db.select(db.cards)
      ..where((c) {
        var condition = c.state.equals(CardState.newCard.index);
        if (deckId != null) condition = condition & c.deckId.equals(deckId);
        return condition;
      })
      ..limit(newLimit);
    newCards = await newQuery.get();
  }

  // Combine
  return [...learningCards, ...reviewCards, ...newCards];
});
