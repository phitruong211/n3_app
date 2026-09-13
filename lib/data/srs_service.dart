import 'dart:math';
import 'package:drift/drift.dart';
import 'database/database.dart';

enum ReviewRating { again, hard, good, easy }
enum CardState { newCard, learning, review, relearning }

class SrsService {
  final AppDatabase db;
  
  static const List<double> learningSteps = [1.0, 10.0]; // minutes
  static const List<double> relearningSteps = [10.0]; // minutes
  static const double graduatingInterval = 1.0; // day
  static const double easyInterval = 4.0; // days
  
  SrsService(this.db);

  double _clampEase(double ease) {
    return max(ease, 1.3);
  }

  double _fuzz(double interval) {
    // +/- 5 to 15%
    final random = Random();
    final factor = 0.05 + random.nextDouble() * 0.10; // 0.05 to 0.15
    final sign = random.nextBool() ? 1.0 : -1.0;
    return interval * (1.0 + sign * factor);
  }

  Future<void> reviewCard(Card card, ReviewRating rating) async {
    final now = DateTime.now();
    
    // Copy current state to modify
    int newState = card.state;
    double newEase = card.easeFactor;
    double newIntervalDays = card.intervalDays;
    int newLapses = card.lapses;
    int newStepIndex = card.learningStepIndex;
    int newReps = card.reps + 1;
    DateTime newDue = now;

    if (card.state == CardState.newCard.index || card.state == CardState.learning.index || card.state == CardState.relearning.index) {
      // Short-term learning/relearning
      final isRelearning = card.state == CardState.relearning.index;
      final steps = isRelearning ? relearningSteps : learningSteps;
      
      if (rating == ReviewRating.again) {
        newStepIndex = 0;
        newDue = now.add(Duration(minutes: steps[0].round()));
        newState = isRelearning ? CardState.relearning.index : CardState.learning.index;
      } else if (rating == ReviewRating.hard) {
        // Repeat current step with slight delay
        newDue = now.add(Duration(minutes: (steps[newStepIndex] * 1.5).round()));
        newState = isRelearning ? CardState.relearning.index : CardState.learning.index;
      } else if (rating == ReviewRating.good) {
        newStepIndex += 1;
        if (newStepIndex >= steps.length) {
          // Graduate
          newState = CardState.review.index;
          newIntervalDays = graduatingInterval;
          newDue = now.add(Duration(days: newIntervalDays.round()));
        } else {
          newDue = now.add(Duration(minutes: steps[newStepIndex].round()));
          newState = isRelearning ? CardState.relearning.index : CardState.learning.index;
        }
      } else if (rating == ReviewRating.easy) {
        // Graduate directly
        newState = CardState.review.index;
        newIntervalDays = easyInterval;
        newDue = now.add(Duration(days: newIntervalDays.round()));
      }
    } else {
      // Long-term review
      if (rating == ReviewRating.again) {
        newLapses += 1;
        newEase = _clampEase(newEase - 0.20);
        newState = CardState.relearning.index;
        newStepIndex = 0;
        newDue = now.add(Duration(minutes: relearningSteps[0].round()));
      } else {
        if (rating == ReviewRating.hard) {
          newEase = _clampEase(newEase - 0.15);
          newIntervalDays = newIntervalDays * 1.2;
        } else if (rating == ReviewRating.good) {
          newIntervalDays = newIntervalDays * newEase;
        } else if (rating == ReviewRating.easy) {
          newEase = _clampEase(newEase + 0.15);
          newIntervalDays = newIntervalDays * newEase * 1.3;
        }
        
        newIntervalDays = _fuzz(newIntervalDays);
        newDue = now.add(Duration(minutes: (newIntervalDays * 24 * 60).round()));
      }
    }

    await db.update(db.cards).replace(
      card.copyWith(
        state: newState,
        easeFactor: newEase,
        intervalDays: newIntervalDays,
        lapses: newLapses,
        learningStepIndex: newStepIndex,
        reps: newReps,
        due: Value(newDue),
      )
    );
  }
}
