import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../providers/srs_provider.dart';
import 'srs_review_tab.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: decksAsync.when(
        data: (decks) {
          final n3Decks = decks.where((d) => d.level == 'N3').toList();
          final n4Decks = decks.where((d) => d.level == 'N4').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLevelSection(context, 'TRÌNH ĐỘ N4', n4Decks),
              const SizedBox(height: 24),
              _buildLevelSection(context, 'TRÌNH ĐỘ N3', n3Decks),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context, String title, List decks) {
    if (decks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return _DeckCard(deckId: deck.id, deckName: deck.name, deckType: deck.type);
          },
        ),
      ],
    );
  }
}

class _DeckCard extends ConsumerWidget {
  final String deckId;
  final String deckName;
  final String deckType;

  const _DeckCard({
    required this.deckId,
    required this.deckName,
    required this.deckType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(deckStatsProvider(deckId));

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SrsReviewTab(deckId: deckId),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              deckType == 'Vocab'
                  ? Icons.menu_book
                  : deckType == 'Kanji'
                      ? Icons.language
                      : Icons.extension,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const Spacer(),
            Text(
              deckType.toUpperCase() + ' DECK',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              deckName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            statsAsync.when(
              data: (stats) {
                final learned = stats.total > 0 ? ((stats.review + stats.relearning) / stats.total) : 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiến độ SRS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${(learned * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: learned,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
