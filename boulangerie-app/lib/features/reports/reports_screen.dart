import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/expense.dart';
import '../../models/report.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';

const _revenueColor = AppColors.success;
const _chargesColor = AppColors.warning;

/// Bénéfice de la semaine ou du mois, avec navigation entre périodes.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.week;
  DateTime _date = today();

  /// Premier jour de la période affichée (lundi ou 1er du mois).
  DateTime get _start => _period == ReportPeriod.week
      ? _date.subtract(Duration(days: _date.weekday - 1))
      : DateTime(_date.year, _date.month);

  DateTime _shift(int direction) => _period == ReportPeriod.week
      ? _start.add(Duration(days: 7 * direction))
      : DateTime(_start.year, _start.month + direction);

  String _label(BuildContext context) {
    final dates = context.dates;
    if (_period == ReportPeriod.month) return dates.monthYear(_start);
    final end = _start.add(const Duration(days: 6));
    return context.l10n.weekLabel(dates.dayMonth(_start), '${dates.dayMonth(end)} ${end.year}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = (_period, _start);
    final report = ref.watch(reportProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<ReportPeriod>(
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 52)),
            segments: [
              ButtonSegment(value: ReportPeriod.week, label: Text(l10n.week), icon: const Icon(Icons.view_week_rounded)),
              ButtonSegment(value: ReportPeriod.month, label: Text(l10n.month), icon: const Icon(Icons.calendar_month_rounded)),
            ],
            selected: {_period},
            onSelectionChanged: (selection) => setState(() => _period = selection.first),
          ),
          const SizedBox(height: 12),
          PeriodNavigator(
            label: _label(context),
            previousTooltip: l10n.previousPeriod,
            nextTooltip: l10n.nextPeriod,
            onPrevious: () => setState(() => _date = _shift(-1)),
            onNext: _shift(1).isAfter(today()) ? null : () => setState(() => _date = _shift(1)),
          ),
          const SizedBox(height: 16),
          AsyncView(
            value: report,
            onRetry: () => ref.invalidate(reportProvider(query)),
            builder: (report) => _ReportBody(report: report, period: _period),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.period});

  final Report report;
  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final positive = report.profit >= 0;
    final profitColor = positive ? AppColors.success : AppColors.danger;
    final charges = report.charges;
    final expenseLines = [
      for (final category in ExpenseCategory.values)
        if ((charges.expensesByCategory[category.name] ?? 0) > 0)
          (l10n.expenseCategoryLabel(category), charges.expensesByCategory[category.name]!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: profitColor.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(positive ? l10n.profit : l10n.loss, style: theme.textTheme.titleLarge?.copyWith(color: profitColor)),
              FittedBox(
                child: Text(
                  formatMoney(report.profit),
                  style: theme.textTheme.displaySmall?.copyWith(color: profitColor, fontWeight: FontWeight.bold),
                ),
              ),
              if (report.partial)
                Text(l10n.partialUntil(context.dates.short(report.asOf)), textAlign: TextAlign.center),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Total(label: l10n.revenue, amount: report.revenue.total, color: _revenueColor)),
          const SizedBox(width: 12),
          Expanded(child: _Total(label: l10n.charges, amount: charges.total, color: _chargesColor)),
        ]),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.revenueVsCharges,
          icon: Icons.bar_chart_rounded,
          child: Column(children: [
            SizedBox(height: 220, child: _Chart(series: report.series, period: period)),
            const SizedBox(height: 8),
            Wrap(spacing: 16, children: [
              _Legend(color: _revenueColor, label: l10n.revenue),
              _Legend(color: _chargesColor, label: l10n.charges),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.revenue,
          icon: Icons.trending_up_rounded,
          child: Column(children: [
            AmountRow(label: l10n.bread, amount: report.revenue.byCategory['bread'] ?? 0),
            AmountRow(label: l10n.juice, amount: report.revenue.byCategory['juice'] ?? 0),
            if (report.revenue.recovered > 0)
              AmountRow(label: '· ${l10n.recovered}', amount: report.revenue.recovered, color: theme.colorScheme.outline),
            const Divider(),
            AmountRow(label: l10n.total, amount: report.revenue.total, bold: true, color: _revenueColor),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.charges,
          icon: Icons.trending_down_rounded,
          child: Column(children: [
            AmountRow(label: l10n.ingredientsCharge, amount: charges.ingredients),
            for (final (label, amount) in expenseLines) AmountRow(label: label, amount: amount),
            AmountRow(label: l10n.salaries, amount: charges.salaries),
            for (final line in charges.salariesByEmployee)
              AmountRow(label: '· ${line.name}', amount: line.amount, color: theme.colorScheme.outline),
            const Divider(),
            AmountRow(label: l10n.total, amount: charges.total, bold: true, color: _chargesColor),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.topProducts,
          icon: Icons.emoji_events_rounded,
          child: report.topProducts.isEmpty
              ? Text(l10n.noData)
              : Column(children: [
                  for (final (index, product) in report.topProducts.indexed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(productLabel(context, nameFr: product.nameFr, nameMg: product.nameMg, format: product.format, size: product.size)),
                      subtitle: Text('× ${formatInt(product.quantity)}'),
                      trailing: Text(formatMoney(product.revenue), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.unsold,
          icon: Icons.delete_sweep_rounded,
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(l10n.quantity)),
              CountText(report.wasteQuantity, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            AmountRow(label: l10n.unsoldValue, amount: report.wasteValue, color: AppColors.danger),
            AmountRow(label: l10n.recovered, amount: report.wasteRecovered, color: AppColors.success),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount, required this.color});

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          FittedBox(
            child: Text(formatMoney(amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

/// Semaine : barres groupées par jour. Mois : deux courbes (31 groupes de barres seraient illisibles).
class _Chart extends StatelessWidget {
  const _Chart({required this.series, required this.period});

  final List<SeriesPoint> series;
  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return Center(child: Text(context.l10n.noData));

    final dates = context.dates;
    final maxValue = series.fold<int>(1, (value, point) => math.max(value, math.max(point.revenue, point.charges)));
    final interval = _niceInterval(maxValue);
    final maxY = (maxValue / interval).ceil() * interval;
    final labelStep = period == ReportPeriod.week ? 1 : 5;

    String shortAmount(double value) =>
        value >= 1000000 ? '${formatQuantity(value / 1000000, decimals: 1)}M' : value >= 1000 ? '${(value / 1000).round()}k' : value.toInt().toString();

    final titles = FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: interval.toDouble(),
          getTitlesWidget: (value, meta) => SideTitleWidget(meta: meta, child: Text(shortAmount(value), style: const TextStyle(fontSize: 11))),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= series.length || index % labelStep != 0) return const SizedBox.shrink();
            final day = series[index].date;
            final text = period == ReportPeriod.week ? dates.shortWeekday(day) : '${day.day}';
            return SideTitleWidget(meta: meta, child: Text(text, style: const TextStyle(fontSize: 12)));
          },
        ),
      ),
    );
    final grid = FlGridData(drawVerticalLine: false, horizontalInterval: interval.toDouble());

    if (period == ReportPeriod.week) {
      return BarChart(BarChartData(
        maxY: maxY.toDouble(),
        titlesData: titles,
        gridData: grid,
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(formatMoney(rod.toY.round()), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        barGroups: [
          for (final (index, point) in series.indexed)
            BarChartGroupData(x: index, barsSpace: 3, barRods: [
              BarChartRodData(toY: point.revenue.toDouble(), color: _revenueColor, width: 12),
              BarChartRodData(toY: point.charges.toDouble(), color: _chargesColor, width: 12),
            ]),
        ],
      ));
    }

    LineChartBarData line(List<int> values, Color color) => LineChartBarData(
          spots: [for (final (index, value) in values.indexed) FlSpot(index.toDouble(), value.toDouble())],
          color: color,
          barWidth: 3,
          isCurved: true,
          preventCurveOverShooting: true,
          dotData: const FlDotData(show: false),
        );

    return LineChart(LineChartData(
      minY: 0,
      maxY: maxY.toDouble(),
      titlesData: titles,
      gridData: grid,
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => [
            for (final spot in spots)
              LineTooltipItem(formatMoney(spot.y.round()), TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      lineBarsData: [
        line([for (final point in series) point.revenue], _revenueColor),
        line([for (final point in series) point.charges], _chargesColor),
      ],
    ));
  }

  /// Pas de graduation lisible : 1, 2 ou 5 × 10^n, environ 4 lignes.
  static int _niceInterval(int maxValue) {
    final raw = maxValue / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final step = [1, 2, 5, 10].firstWhere((factor) => factor * magnitude >= raw) * magnitude;
    return math.max(1, step.round());
  }
}
