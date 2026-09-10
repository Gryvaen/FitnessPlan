import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import '../theme/sport_chrome.dart';
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
    return AppChromeScaffold(
      appBar: AppBar(title: Text(l10n.records)),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SportTabs<RecordsSegment>(
              items: {
                RecordsSegment.body: l10n.segmentBody,
                RecordsSegment.train: l10n.segmentTrain,
                RecordsSegment.notes: l10n.segmentNotes,
              },
              selected: _segment,
              onSelected: (value) => setState(() => _segment = value),
            ),
          ),
          const Divider(),
          Expanded(
            child: switch (_segment) {
              RecordsSegment.body => const BodyRecordsTab(),
              RecordsSegment.train => const TrainRecordsTab(),
              RecordsSegment.notes => const NotesRecordsTab(),
            },
          ),
        ],
      ),
    );
  }
}
