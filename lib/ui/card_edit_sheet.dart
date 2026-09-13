import 'dart:convert';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../data/database/database.dart';
import '../providers/core_providers.dart';

class CardEditSheet extends ConsumerStatefulWidget {
  final Card card;
  const CardEditSheet({super.key, required this.card});

  static Future<void> show(BuildContext context, Card card) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CardEditSheet(card: card),
    );
  }

  @override
  ConsumerState<CardEditSheet> createState() => _CardEditSheetState();
}

class _CardEditSheetState extends ConsumerState<CardEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frontCtrl;
  late TextEditingController _backCtrl;
  late TextEditingController _examplesCtrl;
  late TextEditingController _relatedCtrl;

  @override
  void initState() {
    super.initState();
    _frontCtrl = TextEditingController(text: widget.card.frontText);
    _backCtrl = TextEditingController(text: widget.card.backText);
    
    // Parse JSON arrays back to multiline text
    String examples = '';
    if (widget.card.exampleSentences != null) {
      try {
        final List list = jsonDecode(widget.card.exampleSentences!);
        examples = list.join('\n\n');
      } catch (_) {
        examples = widget.card.exampleSentences!;
      }
    }
    _examplesCtrl = TextEditingController(text: examples);

    String related = '';
    if (widget.card.relatedWords != null) {
      try {
        final List list = jsonDecode(widget.card.relatedWords!);
        related = list.join('\n');
      } catch (_) {
        related = widget.card.relatedWords!;
      }
    }
    _relatedCtrl = TextEditingController(text: related);
  }

  @override
  void dispose() {
    _frontCtrl.dispose();
    _backCtrl.dispose();
    _examplesCtrl.dispose();
    _relatedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    
    String? newExamples;
    if (_examplesCtrl.text.trim().isNotEmpty) {
      newExamples = jsonEncode(_examplesCtrl.text.trim().split('\n\n'));
    }

    String? newRelated;
    if (_relatedCtrl.text.trim().isNotEmpty) {
      newRelated = jsonEncode(_relatedCtrl.text.trim().split('\n'));
    }

    final updatedCard = widget.card.copyWith(
      frontText: _frontCtrl.text.trim(),
      backText: _backCtrl.text.trim(),
      exampleSentences: drift.Value(newExamples),
      relatedWords: drift.Value(newRelated),
      updatedAt: drift.Value(DateTime.now()),
      syncStatus: 1, // Pending sync
    );

    await db.update(db.cards).replace(updatedCard);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frontCtrl,
                decoration: const InputDecoration(labelText: 'Front Text (Required)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backCtrl,
                decoration: const InputDecoration(labelText: 'Back Text (Required)', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _examplesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Example Sentences (Optional)',
                  hintText: 'Separate examples with double newlines',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relatedCtrl,
                decoration: const InputDecoration(
                  labelText: 'Related Words (Optional)',
                  hintText: 'Separate words with newlines',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
