import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageTitle(
              title: l10n.records,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                8,
                AppSpacing.listPage,
                AppSpacing.compact,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.listPage,
              ),
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
            const SizedBox(height: AppSpacing.compact),
            Expanded(
              child: SwipeTabView(
                branchIndex: 2,
                keepPagesAlive: true,
                index: _segment.index,
                onIndexChanged: (i) =>
                    setState(() => _segment = RecordsSegment.values[i]),
                children: const [
                  BodyRecordsTab(),
                  TrainRecordsTab(),
                  NotesRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
