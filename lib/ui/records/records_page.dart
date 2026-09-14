import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations_ext.dart';
import '../shell/swipe_tab_view.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import 'body_records_tab.dart';
import 'notes_records_tab.dart';
import 'train_records_tab.dart';

enum RecordsSegment { body, train, notes }

class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({
    super.key,
    this.initialSegment = RecordsSegment.body,
    this.initialTrainTab,
  });

  final RecordsSegment initialSegment;

  /// When set (e.g. navigating in via `/records?tab=train&sub=library`),
  /// forces the 训练 sub-tab (0=计划, 1=动作库, 2=历史) to this index even if
  /// [TrainRecordsTab] kept a different one alive from an earlier visit.
  final int? initialTrainTab;

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  late RecordsSegment _segment;
  int? _trainTab;

  /// Last applied `matchedLocation + query` so we react when Today (or
  /// anywhere) calls `context.go('/records?tab=train&…')` while this shell
  /// branch is already mounted — the page State is kept alive and would
  /// otherwise ignore the new query.
  String? _appliedRouteKey;

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
    _trainTab = widget.initialTrainTab;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromRoute();
  }

  String _routeKey(GoRouterState state) =>
      '${state.matchedLocation}?${state.uri.query}';

  void _syncFromRoute() {
    final state = GoRouterState.of(context);
    // Nested routes like /records/plan keep this page under the shell but
    // must not steal the visible segment from query params on the child.
    if (state.matchedLocation != '/records') return;

    final key = _routeKey(state);
    if (key == _appliedRouteKey) return;
    _appliedRouteKey = key;

    final tab = state.uri.queryParameters['tab'];
    final segment = switch (tab) {
      'train' => RecordsSegment.train,
      'notes' => RecordsSegment.notes,
      'body' => RecordsSegment.body,
      // No tab → leave the user's current segment (e.g. after `go('/records')`).
      null || '' => null,
      _ => RecordsSegment.body,
    };
    final sub = state.uri.queryParameters['sub'];
    final trainTab = switch (sub) {
      'plans' => 0,
      'library' => 1,
      'history' => 2,
      _ => null,
    };

    final nextSegment = segment ?? _segment;
    final nextTrain = trainTab ?? _trainTab;
    if (nextSegment == _segment && nextTrain == _trainTab) return;
    setState(() {
      _segment = nextSegment;
      _trainTab = nextTrain;
    });
  }

  String _trainSubName(int tab) => switch (tab) {
    1 => 'library',
    2 => 'history',
    _ => 'plans',
  };

  void _selectSegment(RecordsSegment value) {
    if (value == _segment) return;
    setState(() => _segment = value);
    final path = switch (value) {
      RecordsSegment.body => '/records',
      RecordsSegment.notes => '/records?tab=notes',
      RecordsSegment.train => _trainTab == null
          ? '/records?tab=train'
          : '/records?tab=train&sub=${_trainSubName(_trainTab!)}',
    };
    // Mark before go so the echo from didChangeDependencies is a no-op.
    _appliedRouteKey = path.contains('?')
        ? '/records?${Uri.parse(path).query}'
        : '/records?';
    context.go(path);
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
                onSelected: _selectSegment,
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            Expanded(
              child: SwipeTabView(
                branchIndex: 2,
                keepPagesAlive: true,
                index: _segment.index,
                onIndexChanged: (i) =>
                    _selectSegment(RecordsSegment.values[i]),
                children: [
                  const BodyRecordsTab(),
                  TrainRecordsTab(initialTab: _trainTab),
                  const NotesRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
