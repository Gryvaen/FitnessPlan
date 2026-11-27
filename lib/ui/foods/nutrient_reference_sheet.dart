import 'package:flutter/material.dart';

import '../../l10n/app_localizations_ext.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';

/// 「每日营养参考」底部弹层：成年人每天在热量和三大营养素以外的建议摄入量。
///
/// 上半部分是一张固定参考表（通用值，不读档案或当天记录），每行只有名称和
/// 数值；性别不同的项写成「男 X / 女 Y」。所有说明（作用、来源、提示）统一放在
/// 底部的「营养素介绍」里，默认折叠，点标题按同样的分组顺序逐项展开。
void showNutrientReferenceSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) =>
          NutrientReferenceList(controller: controller),
    ),
  );
}

class NutrientReferenceList extends StatefulWidget {
  const NutrientReferenceList({super.key, this.controller});

  final ScrollController? controller;

  @override
  State<NutrientReferenceList> createState() => _NutrientReferenceListState();
}

class _NutrientReferenceListState extends State<NutrientReferenceList> {
  /// 「营养素介绍」 starts folded so the sheet opens on the numbers.
  bool _guideOpen = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final groups = _groups(l10n);
    return SafeArea(
      top: false,
      child: ListView(
        key: const ValueKey('nutrientReferenceSheet'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          0,
          AppSpacing.formPage,
          AppSpacing.formPage,
        ),
        children: [
          Text(l10n.nutrientRef, style: theme.textTheme.sectionTitle),
          const SizedBox(height: 4),
          Text(
            l10n.nutrientRefSubtitle,
            style: theme.textTheme.meta?.copyWith(color: muted),
          ),
          for (final group in groups) ...[
            const SizedBox(height: AppSpacing.section),
            Text(group.title, style: theme.textTheme.subsectionTitle),
            const SizedBox(height: 4),
            for (final (i, row) in group.rows.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _ValueRow(row: row),
            ],
          ],
          const SizedBox(height: AppSpacing.section),
          Semantics(
            expanded: _guideOpen,
            hint: _guideOpen ? l10n.collapseSection : l10n.expandSection,
            child: InkWell(
              key: const ValueKey('nutrientGuide'),
              onTap: () => setState(() => _guideOpen = !_guideOpen),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.nutrientRefGuideTitle,
                            style: theme.textTheme.sectionTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.nutrientRefGuideHint,
                            style: theme.textTheme.meta?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.field),
                    InkIcon(
                      _guideOpen ? InkGlyph.collapse : InkGlyph.expand,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_guideOpen)
            for (final group in groups) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(group.title, style: theme.textTheme.subsectionTitle),
              const SizedBox(height: 4),
              for (final (i, row) in group.rows.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _GuideEntry(row: row),
              ],
              const SizedBox(height: AppSpacing.compact),
            ],
          const SizedBox(height: AppSpacing.section),
          Text(
            l10n.nutrientRefFootnote,
            style: theme.textTheme.meta?.copyWith(color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RefGroup {
  const _RefGroup(this.title, this.rows);

  final String title;
  final List<_RefRow> rows;
}

class _RefRow {
  const _RefRow(
    this.name,
    this.value, {
    required this.role,
    required this.source,
    this.note,
  });

  final String name;
  final String value;

  /// 作用。
  final String role;

  /// 食物来源。
  final String source;

  /// 提示（换算、上限、特殊人群等）。
  final String? note;
}

List<_RefGroup> _groups(AppLocalizations l10n) => [
  _RefGroup(l10n.nutrientRefGroupLimit, [
    _RefRow(
      l10n.sodium,
      '≤ 2000 mg',
      role: l10n.nutrientRefSodiumRole,
      source: l10n.nutrientRefSodiumSource,
      note: l10n.nutrientRefSodiumNote,
    ),
    _RefRow(
      l10n.saturatedFat,
      l10n.nutrientRefSatFatValue,
      role: l10n.nutrientRefSatFatRole,
      source: l10n.nutrientRefSatFatSource,
      note: l10n.nutrientRefSatFatNote,
    ),
    _RefRow(
      l10n.nutrientRefTransFat,
      '< 2 g',
      role: l10n.nutrientRefTransFatRole,
      source: l10n.nutrientRefTransFatSource,
      note: l10n.nutrientRefTransFatNote,
    ),
    _RefRow(
      l10n.nutrientRefAddedSugar,
      l10n.nutrientRefAddedSugarValue,
      role: l10n.nutrientRefAddedSugarRole,
      source: l10n.nutrientRefAddedSugarSource,
      note: l10n.nutrientRefAddedSugarNote,
    ),
    _RefRow(
      l10n.nutrientRefCholesterol,
      l10n.nutrientRefCholesterolValue,
      role: l10n.nutrientRefCholesterolRole,
      source: l10n.nutrientRefCholesterolSource,
      note: l10n.nutrientRefCholesterolNote,
    ),
    _RefRow(
      l10n.alcohol,
      '≤ 15 g',
      role: l10n.nutrientRefAlcoholRole,
      source: l10n.nutrientRefAlcoholSource,
      note: l10n.nutrientRefAlcoholNote,
    ),
    _RefRow(
      l10n.nutrientRefCaffeine,
      '≤ 400 mg',
      role: l10n.nutrientRefCaffeineRole,
      source: l10n.nutrientRefCaffeineSource,
      note: l10n.nutrientRefCaffeineNote,
    ),
  ]),
  _RefGroup(l10n.nutrientRefGroupFats, [
    _RefRow(
      l10n.nutrientRefTotalFat,
      l10n.nutrientRefTotalFatValue,
      role: l10n.nutrientRefTotalFatRole,
      source: l10n.nutrientRefTotalFatSource,
    ),
    _RefRow(
      l10n.nutrientRefOmega6,
      l10n.nutrientRefOmega6Value,
      role: l10n.nutrientRefOmega6Role,
      source: l10n.nutrientRefOmega6Source,
      note: l10n.nutrientRefOmega6Note,
    ),
    _RefRow(
      l10n.nutrientRefOmega3,
      l10n.nutrientRefOmega3Value,
      role: l10n.nutrientRefOmega3Role,
      source: l10n.nutrientRefOmega3Source,
    ),
    _RefRow(
      'EPA + DHA',
      '0.25–2 g',
      role: l10n.nutrientRefEpaDhaRole,
      source: l10n.nutrientRefEpaDhaSource,
      note: l10n.nutrientRefEpaDhaNote,
    ),
    _RefRow(
      l10n.nutrientRefMufa,
      l10n.nutrientRefMufaValue,
      role: l10n.nutrientRefMufaRole,
      source: l10n.nutrientRefMufaSource,
    ),
  ]),
  _RefGroup(l10n.nutrientRefGroupEnough, [
    _RefRow(
      l10n.fiber,
      '25–30 g',
      role: l10n.nutrientRefFiberRole,
      source: l10n.nutrientRefFiberSource,
    ),
    _RefRow(
      l10n.nutrientRefPotassium,
      '3600 mg',
      role: l10n.nutrientRefPotassiumRole,
      source: l10n.nutrientRefPotassiumSource,
      note: l10n.nutrientRefPotassiumNote,
    ),
    _RefRow(
      l10n.nutrientRefWater,
      l10n.nutrientRefWaterValue,
      role: l10n.nutrientRefWaterRole,
      source: l10n.nutrientRefWaterSource,
      note: l10n.nutrientRefWaterNote,
    ),
  ]),
  _RefGroup(l10n.nutrientRefGroupMinerals, [
    _RefRow(
      l10n.calcium,
      '800 mg',
      role: l10n.nutrientRefCalciumRole,
      source: l10n.nutrientRefCalciumSource,
      note: l10n.nutrientRefCalciumNote,
    ),
    _RefRow(
      l10n.nutrientRefIron,
      l10n.nutrientRefIronValue,
      role: l10n.nutrientRefIronRole,
      source: l10n.nutrientRefIronSource,
    ),
    _RefRow(
      l10n.nutrientRefZinc,
      l10n.nutrientRefZincValue,
      role: l10n.nutrientRefZincRole,
      source: l10n.nutrientRefZincSource,
    ),
    _RefRow(
      l10n.nutrientRefMagnesium,
      '330 mg',
      role: l10n.nutrientRefMagnesiumRole,
      source: l10n.nutrientRefMagnesiumSource,
    ),
    _RefRow(
      l10n.nutrientRefPhosphorus,
      '720 mg',
      role: l10n.nutrientRefPhosphorusRole,
      source: l10n.nutrientRefPhosphorusSource,
    ),
    _RefRow(
      l10n.nutrientRefIodine,
      '120 μg',
      role: l10n.nutrientRefIodineRole,
      source: l10n.nutrientRefIodineSource,
    ),
    _RefRow(
      l10n.nutrientRefSelenium,
      '60 μg',
      role: l10n.nutrientRefSeleniumRole,
      source: l10n.nutrientRefSeleniumSource,
    ),
  ]),
  _RefGroup(l10n.nutrientRefGroupVitamins, [
    _RefRow(
      l10n.nutrientRefVitaminA,
      l10n.nutrientRefVitaminAValue,
      role: l10n.nutrientRefVitaminARole,
      source: l10n.nutrientRefVitaminASource,
    ),
    _RefRow(
      l10n.nutrientRefVitaminD,
      '10 μg (400 IU)',
      role: l10n.nutrientRefVitaminDRole,
      source: l10n.nutrientRefVitaminDSource,
      note: l10n.nutrientRefVitaminDNote,
    ),
    _RefRow(
      l10n.nutrientRefVitaminE,
      '14 mg α-TE',
      role: l10n.nutrientRefVitaminERole,
      source: l10n.nutrientRefVitaminESource,
    ),
    _RefRow(
      l10n.nutrientRefVitaminK,
      '80 μg',
      role: l10n.nutrientRefVitaminKRole,
      source: l10n.nutrientRefVitaminKSource,
    ),
    _RefRow(
      l10n.nutrientRefVitaminB1,
      l10n.nutrientRefVitaminB1B2Value,
      role: l10n.nutrientRefVitaminB1Role,
      source: l10n.nutrientRefVitaminB1Source,
    ),
    _RefRow(
      l10n.nutrientRefVitaminB2,
      l10n.nutrientRefVitaminB1B2Value,
      role: l10n.nutrientRefVitaminB2Role,
      source: l10n.nutrientRefVitaminB2Source,
    ),
    _RefRow(
      l10n.nutrientRefVitaminB12,
      '2.4 μg',
      role: l10n.nutrientRefVitaminB12Role,
      source: l10n.nutrientRefVitaminB12Source,
    ),
    _RefRow(
      l10n.nutrientRefFolate,
      '400 μg DFE',
      role: l10n.nutrientRefFolateRole,
      source: l10n.nutrientRefFolateSource,
    ),
    _RefRow(
      l10n.nutrientRefVitaminC,
      '100 mg',
      role: l10n.nutrientRefVitaminCRole,
      source: l10n.nutrientRefVitaminCSource,
      note: l10n.nutrientRefVitaminCNote,
    ),
  ]),
  _RefGroup(l10n.nutrientRefGroupOther, [
    _RefRow(
      l10n.nutrientRefPurine,
      l10n.nutrientRefPurineValue,
      role: l10n.nutrientRefPurineRole,
      source: l10n.nutrientRefPurineSource,
      note: l10n.nutrientRefPurineNote,
    ),
  ]),
];

/// Reference-table row: name on the left, the recommended amount on the right.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.row});

  final _RefRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(row.name, style: theme.textTheme.rowTitle),
          ),
          const SizedBox(width: AppSpacing.field),
          Expanded(
            flex: 2,
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: theme.textTheme.rowValue,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「认识这些营养素」 entry: name, then 作用 / 来源 / 提示 paragraphs.
class _GuideEntry extends StatelessWidget {
  const _GuideEntry({required this.row});

  final _RefRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final note = row.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.name, style: theme.textTheme.rowTitle),
          const SizedBox(height: 6),
          _GuideLine(label: l10n.nutrientRefRoleLabel, text: row.role),
          const SizedBox(height: 4),
          _GuideLine(label: l10n.nutrientRefSourceLabel, text: row.source),
          if (note != null) ...[
            const SizedBox(height: 4),
            _GuideLine(label: l10n.nutrientRefNoteLabel, text: note),
          ],
        ],
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyText?.copyWith(height: 1.5);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: theme.textTheme.meta?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: body,
    );
  }
}
