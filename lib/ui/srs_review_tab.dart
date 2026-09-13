import 'dart:math';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/srs_service.dart';
import '../providers/core_providers.dart';
import '../providers/srs_provider.dart';
import 'card_edit_sheet.dart';

class SrsReviewTab extends ConsumerStatefulWidget {
  final String? deckId;
  const SrsReviewTab({super.key, this.deckId});

  @override
  ConsumerState<SrsReviewTab> createState() => _SrsReviewTabState();
}

class _SrsReviewTabState extends ConsumerState<SrsReviewTab> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  void _onRate(Card card, ReviewRating rating, WidgetRef ref) async {
    final srs = ref.read(srsServiceProvider);
    final counters = ref.read(dailyCountersProvider.notifier);
    
    // Increment counters based on the initial state of the card
    if (card.state == CardState.newCard.index) {
      counters.incrementNew();
    } else if (card.state == CardState.review.index) {
      counters.incrementReview();
    }

    await srs.reviewCard(card, rating);
    
    // Invalidate due cards so the queue is refreshed (or just move to next in local list if we want to avoid reloading)
    // For simplicity, we just move to the next card locally until we run out, then refresh.
    setState(() {
      _currentIndex++;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dueCardsAsync = ref.watch(dueCardsProvider(widget.deckId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckId == null ? 'SRS Review' : 'Deck Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dueCardsProvider(widget.deckId));
              setState(() {
                _currentIndex = 0;
                _isFlipped = false;
              });
            },
          )
        ],
      ),
      body: dueCardsAsync.when(
        data: (cards) {
          if (_currentIndex >= cards.length) {
            return const Center(child: Text('All done for now! 🎉\nCheck back later.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)));
          }

          final card = cards[_currentIndex];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Card ${_currentIndex + 1} of ${cards.length}', style: TextStyle(color: Colors.grey.shade600)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isFlipped) setState(() => _isFlipped = true);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: _flipTransition,
                    layoutBuilder: (widget, list) => Stack(children: [if (widget != null) widget, ...list]),
                    child: _isFlipped ? _buildBack(card) : _buildFront(card),
                  ),
                ),
              ),
              if (_isFlipped) _buildActionButtons(card, ref),
              if (!_isFlipped)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isFlipped = true),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Show Answer'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _flipTransition(Widget child, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: child,
      builder: (context, widget) {
        final isUnder = (ValueKey(_isFlipped) != widget?.key);
        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        tilt *= isUnder ? -1.0 : 1.0;
        final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
        return Transform(
          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
          alignment: Alignment.center,
          child: widget,
        );
      },
    );
  }

  Widget _buildFront(Card card) {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              card.frontText,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                CardEditSheet.show(context, card).then((_) {
                  // optionally invalidate provider if you want live refresh
                  ref.invalidate(dueCardsProvider(null));
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBack(Card card) {
    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    card.frontText,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    CardEditSheet.show(context, card).then((_) {
                      ref.invalidate(dueCardsProvider(null));
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              card.backText,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // We can parse example sentences / related words from JSON if needed
            // depending on what was imported.
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Card card, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRatingBtn('Again', Colors.red, () => _onRate(card, ReviewRating.again, ref)),
          _buildRatingBtn('Hard', Colors.orange, () => _onRate(card, ReviewRating.hard, ref)),
          _buildRatingBtn('Good', Colors.green, () => _onRate(card, ReviewRating.good, ref)),
          _buildRatingBtn('Easy', Colors.blue, () => _onRate(card, ReviewRating.easy, ref)),
        ],
      ),
    );
  }

  Widget _buildRatingBtn(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
