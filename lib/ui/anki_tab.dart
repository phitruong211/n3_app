import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/srs_provider.dart';

class AnkiTab extends ConsumerStatefulWidget {
  const AnkiTab({super.key});

  @override
  ConsumerState<AnkiTab> createState() => _AnkiTabState();
}

class _AnkiTabState extends ConsumerState<AnkiTab> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final counters = ref.watch(dailyCountersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Anki Stats & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            title: 'Today\'s Progress',
            children: [
              _StatRow(label: 'New Cards Studied', value: '${counters.newStudied} / ${settings.dailyNewLimit}'),
              const Divider(),
              _StatRow(label: 'Review Cards Studied', value: '${counters.reviewStudied} / ${settings.dailyReviewLimit}'),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            title: 'Configuration',
            children: [
              ListTile(
                title: const Text('Daily New Limit'),
                trailing: Text('${settings.dailyNewLimit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () => _showEditLimit(context, 'New Limit', settings.dailyNewLimit, (v) {
                  ref.read(settingsProvider.notifier).updateLimits(newLimit: v);
                }),
              ),
              const Divider(),
              ListTile(
                title: const Text('Daily Review Limit'),
                trailing: Text('${settings.dailyReviewLimit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () => _showEditLimit(context, 'Review Limit', settings.dailyReviewLimit, (v) {
                  ref.read(settingsProvider.notifier).updateLimits(reviewLimit: v);
                }),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showEditLimit(BuildContext context, String title, int current, ValueChanged<int> onSave) {
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null) onSave(val);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }
}
