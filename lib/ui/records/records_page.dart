import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import 'body_records_tab.dart';
import 'notes_records_tab.dart';
import 'train_records_tab.dart';

enum RecordsSegment { body, train, notes }

class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key, this.initialSegment = RecordsSegment.body});

  final RecordsSegment initialSegment;

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  late RecordsSegment _segment;

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
  }

  @override
  void didUpdateWidget(covariant RecordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSegment != oldWidget.initialSegment) {
      _segment = widget.initialSegment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.records),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<RecordsSegment>(
              segments: [
                ButtonSegment(
                  value: RecordsSegment.body,
                  label: Text(l10n.segmentBody),
                  icon: const Icon(Icons.monitor_weight_outlined, size: 18),
                ),
                ButtonSegment(
                  value: RecordsSegment.train,
                  label: Text(l10n.segmentTrain),
                  icon: const Icon(Icons.fitness_center, size: 18),
                ),
                ButtonSegment(
                  value: RecordsSegment.notes,
                  label: Text(l10n.segmentNotes),
                  icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
        ),
      ),
      body: switch (_segment) {
        RecordsSegment.body => const BodyRecordsTab(),
        RecordsSegment.train => const TrainRecordsTab(),
        RecordsSegment.notes => const NotesRecordsTab(),
      },
    );
  }
}
