import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _bodyKey = GlobalKey<BodyRecordsTabState>();

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

  Future<void> _onFab() async {
    switch (_segment) {
      case RecordsSegment.body:
        await _bodyKey.currentState?.addWeight();
        return;
      case RecordsSegment.train:
        await context.push('/records/plan');
        return;
      case RecordsSegment.notes:
        await context.push(noteEditPath(DateTime.now()));
    }
  }

  String _fabTooltip(AppLocalizations l10n) => switch (_segment) {
        RecordsSegment.body => l10n.fabLogWeight,
        RecordsSegment.train => l10n.fabNewPlan,
        RecordsSegment.notes => l10n.fabWriteNote,
      };

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
      floatingActionButton: FloatingActionButton(
        onPressed: _onFab,
        tooltip: _fabTooltip(l10n),
        child: const Icon(Icons.add),
      ),
      body: switch (_segment) {
        RecordsSegment.body => BodyRecordsTab(key: _bodyKey),
        RecordsSegment.train => const TrainRecordsTab(),
        RecordsSegment.notes => const NotesRecordsTab(),
      },
    );
  }
}
