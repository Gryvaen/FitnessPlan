part of 'cultivation_page.dart';

const _kPanelInk = kBalanceInkColor;

/// 天秤宽度占屏宽的比例；顶端距 AppBar 下沿的留白（占屏高）。
const kMaintainBalanceWidthFactor = 0.94;
const kMaintainBalanceTopGapFraction = 0.06;

/// 维持境界主页：宣纸上的「日月同衡」水墨天秤（本次维持的累计亏/盈）+ 心境（平衡日）。
class _MaintainHome extends ConsumerStatefulWidget {
  const _MaintainHome();

  @override
  ConsumerState<_MaintainHome> createState() => _MaintainHomeState();
}

class _MaintainHomeState extends ConsumerState<_MaintainHome> {
  bool _collapsed = false;

  void _toggle() => setState(() => _collapsed = !_collapsed);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in [kBalanceBackgroundAsset, ...kBalanceAssets]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v > 150) setState(() => _collapsed = true);
    if (v < -150) setState(() => _collapsed = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Keep the history provider alive while this screen is open.
    ref.watch(maintainHistoryProvider);
    final balance = ref.watch(maintainBalanceProvider);
    final mind = ref.watch(mindProgressProvider);
    final today = ref.watch(maintainTodayEntryProvider);
    final segmentStart = ref
        .watch(maintainCultivationStateProvider)
        .openSegment
        ?.start;

    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final scaleWidth = size.width * kMaintainBalanceWidthFactor;
    final netStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: _kPanelInk,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kBalancePaperColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _kPanelInk,
        leading: BackButton(onPressed: () => context.go('/profile')),
        title: Text(l10n.cultivationPageTitle),
        // 操作收进标题栏，天秤的右盘不会和它们重叠。
        actions: [
          _SideAction(
            glyph: InkGlyph.chart,
            label: l10n.cultivationSideHistory,
            onTap: () => context.push('/profile/cultivation/maintain-history'),
          ),
          _SideAction(
            glyph: InkGlyph.trophy,
            label: l10n.cultivationSideRealmGuide,
            onTap: () => _showMaintainGuide(context, ref),
          ),
          _SideAction(
            glyph: InkGlyph.settings,
            label: l10n.cultivationSideSettings,
            onTap: () => context.push('/profile/cultivation/settings'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 宣纸 + 淡墨远山。
          Image.asset(
            kBalanceBackgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
          ),
          // 天秤：画面主角，横梁倾角 = 本次维持累计盈亏。
          Positioned(
            left: (size.width - scaleWidth) / 2,
            width: scaleWidth,
            top: topInset + size.height * kMaintainBalanceTopGapFraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  key: const ValueKey('maintain-balance-scale'),
                  width: scaleWidth,
                  height: scaleWidth / kBalanceScaleAspect,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: BalanceScale(
                          tiltRadians: balance.tiltRadians,
                          leftShare: balance.leftShare,
                          rightShare: balance.rightShare,
                          leftCaption: l10n.maintainBalanceDeficitPan,
                          rightCaption: l10n.maintainBalanceSurplusPan,
                          leftValue: '−${formatKcal(balance.leftKcal)}',
                          rightValue: '+${formatKcal(balance.rightKcal)}',
                        ),
                      ),
                      // 落款朱印，钤在砚台右侧。
                      Positioned(
                        right: scaleWidth * 0.1,
                        bottom: scaleWidth * 0.02,
                        child: Image.asset(
                          kBalanceSealAsset,
                          width: 38,
                          gaplessPlayback: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  balance.weighedDays == 0
                      ? l10n.maintainBalanceEmpty
                      : l10n.maintainBalanceNet(
                          formatSignedKcal(balance.netKcal),
                          formatSignedKg(balance.netKcal / kKcalPerKg),
                        ),
                  textAlign: TextAlign.center,
                  style: netStyle,
                ),
                if (segmentStart != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.maintainBalanceSince(
                      DateFormat('M/d').format(segmentStart),
                      '${balance.weighedDays}',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _kPanelInk.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onVerticalDragEnd: _onDragEnd,
              child: _MaintainPanel(
                collapsed: _collapsed,
                mind: mind,
                today: today,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintainPanel extends StatelessWidget {
  const _MaintainPanel({
    required this.collapsed,
    required this.mind,
    required this.today,
  });

  final bool collapsed;
  final MindProgress mind;
  final MaintainDayEntry? today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final realm = mind.realm;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: _kPanelInk.withValues(alpha: 0.6),
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: collapsed ? const Offset(0, 1) : Offset.zero,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: kBalancePaperColor.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: _kPanelInk.withValues(alpha: 0.18)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A4A32).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _kPanelInk.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              l10n.cultivationLayerBadge(realm.label(l10n), '${mind.layer}'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: realm.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= kCultivationLayers; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  _LayerDot(
                    state: i < mind.layer
                        ? _DotState.done
                        : i == mind.layer
                        ? _DotState.current
                        : _DotState.future,
                    color: realm.textColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (mind.isMax) ...[
              Text(
                l10n.maintainMaxCaption,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.maintainMaxSubcaption('${mind.balancedDays}'),
                style: muted,
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: _kPanelInk.withValues(alpha: 0.10)),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: mind.layerProgress,
                        child: ColoredBox(color: realm.textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.maintainNextRealmCaption(
                  '${mind.balancedDays}',
                  '${mind.daysToNextRealm}',
                  realm.next!.label(l10n),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: _kPanelInk.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(children: [_TodayLine(today: today)]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayLine extends StatelessWidget {
  const _TodayLine({required this.today});

  final MaintainDayEntry? today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: _kPanelInk.withValues(alpha: 0.65));
    final entry = today;
    if (entry == null) {
      return Text(
        l10n.maintainTodayPending,
        style: style,
        textAlign: TextAlign.center,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.maintainTodayNet(formatSignedKcal(entry.netKcal)),
          style: style,
        ),
        if (entry.balanced) ...[
          const SizedBox(width: 8),
          _MaintainTag(
            label: l10n.maintainBalancedTag,
            color: FitnessGoal.maintain.cultivationAccentColor,
          ),
        ],
        if (entry.estimated) ...[
          const SizedBox(width: 8),
          _MaintainTag(
            label: l10n.maintainEstimatedTag,
            color: kBalanceSurplusColor,
          ),
        ],
      ],
    );
  }
}

class _MaintainTag extends StatelessWidget {
  const _MaintainTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// 「境界体系」底部弹窗：结算规则 + 心境阶梯。
void _showMaintainGuide(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final tdee = ref.read(profileProvider)?.tdee;
  final current = ref.read(mindProgressProvider).realm;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.maintainGuideTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                l10n.maintainGuideBody,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.maintainGuideBalancedRule(
                  formatKcal(
                    tdee == null
                        ? kMaintainBalancedMinKcal
                        : maintainBalanceThresholdKcal(tdee),
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              for (final r in MindRealm.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: _LayerDot(
                    state: r == current ? _DotState.current : _DotState.done,
                    color: r.textColor,
                  ),
                  title: Text(
                    r.label(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: r.textColor,
                      fontWeight: r == current ? FontWeight.w700 : null,
                    ),
                  ),
                  trailing: Text(
                    l10n.maintainGuideTierDays('${r.floorDays}'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
