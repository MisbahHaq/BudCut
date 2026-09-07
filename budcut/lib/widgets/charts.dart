import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../currency.dart';
import '../theme.dart';

const _tooltipColor = Colors.white;

/// Daily spending bar chart (brutalist : black bars, hard tooltips).
class DailyBarChart extends StatelessWidget {
  final List<({DateTime day, num amount})> data;
  final List<Color> barColors;
  final double height;
  final int maxLabels;
  final Currency currency;

  const DailyBarChart({
    super.key,
    required this.data,
    this.barColors = const [AppTheme.ink],
    this.height = 180,
    this.maxLabels = 7,
    this.currency = Currencies.pkr,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<num>(0, (m, d) => d.amount > m ? d.amount : m);
    final upper = maxY <= 0 ? 1.0 : (maxY * 1.15).toDouble();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: upper,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: upper / 4,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppTheme.ink.withValues(alpha: 0.18),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: upper / 4,
                getTitlesWidget: (v, meta) => Text(
                  _compact(v),
                  style: const TextStyle(
                    fontSize: 9,
                    fontFamily: AppTheme.mono,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: data.length > 1
                    ? (data.length / maxLabels).ceilToDouble()
                    : 1,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final day = data[idx].day;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${day.day}/${day.month}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: AppTheme.mono,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _tooltipColor,
              tooltipBorder: const BorderSide(color: AppTheme.ink, width: 2),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = data[group.x.toInt()];
                return BarTooltipItem(
                  '${d.day.day}/${d.day.month}\n'
                  '${Money(d.amount).formatFor(currency)}',
                  const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 10,
                    fontFamily: AppTheme.mono,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].amount.toDouble(),
                    width: (data.length > 30) ? 5 : 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                    color: barColors.isEmpty
                        ? AppTheme.ink
                        : barColors[i % barColors.length],
                    borderSide: const BorderSide(color: AppTheme.ink, width: 1.2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _compact(num v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(k >= 100 ? 0 : 1)}k';
    }
    return v.toStringAsFixed(0);
  }
}

/// Stacked multi-category bar chart for quarterly view.
class StackedBarChart extends StatelessWidget {
  final List<({DateTime month, Map<String, num> byCat})> data;
  final List<Color> colors;
  final double height;
  final Currency currency;

  const StackedBarChart({
    super.key,
    required this.data,
    required this.colors,
    this.height = 200,
    this.currency = Currencies.pkr,
  });

  @override
  Widget build(BuildContext context) {
    final totals = data.map((d) => d.byCat.values.fold<num>(0, (s, v) => s + v)).toList();
    final maxTotal = totals.fold<num>(0, (m, v) => v > m ? v : m);
    final upper = maxTotal <= 0 ? 1.0 : (maxTotal * 1.15).toDouble();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: upper,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: upper / 4,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppTheme.ink.withValues(alpha: 0.18),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: upper / 4,
                getTitlesWidget: (v, meta) => Text(
                  v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 9,
                    fontFamily: AppTheme.mono,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _monthName(data[idx].month),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _tooltipColor,
              tooltipBorder: const BorderSide(color: AppTheme.ink, width: 2),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = data[group.x.toInt()];
                final cats = d.byCat.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final buf = StringBuffer('${_monthName(d.month)}\n');
                for (final e in cats.take(5)) {
                  buf.writeln('${e.key}: ${Money(e.value).formatFor(currency)}');
                }
                return BarTooltipItem(
                  buf.toString(),
                  const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 10,
                    fontFamily: AppTheme.mono,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++) _group(i, data[i], colors),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _group(
    int index,
    ({DateTime month, Map<String, num> byCat}) d,
    List<Color> palette,
  ) {
    final rods = _rods(d, palette);
    return BarChartGroupData(
      x: index,
      barRods: [
        for (var c = 0; c < rods.length; c++)
          BarChartRodData(
            toY: rods[c].value.toDouble(),
            width: 36,
            borderRadius: BorderRadius.zero,
            color: rods[c].color,
            borderSide: c == 0
                ? const BorderSide(color: AppTheme.ink, width: 1.2)
                : BorderSide.none,
          ),
      ],
    );
  }

  List<({Color color, num value})> _rods(
    ({DateTime month, Map<String, num> byCat}) d,
    List<Color> palette,
  ) {
    final sorted = d.byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (var i = 0; i < sorted.length; i++)
        (color: palette[i % palette.length], value: sorted[i].value),
    ];
  }

  String _monthName(DateTime m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m.month - 1];
  }
}

/// Donut chart for category distribution (pastel slices w/ black outlines).
class CategoryDonut extends StatelessWidget {
  final List<({String label, num value, Color color})> slices;
  final double size;
  final String centerTop;
  final String centerBottom;

  const CategoryDonut({
    super.key,
    required this.slices,
    this.size = 200,
    this.centerTop = '',
    this.centerBottom = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.34,
              startDegreeOffset: -90,
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppTheme.ink, width: 2),
              ),
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.value > 0 ? s.value.toDouble() : 0,
                    color: s.color,
                    radius: size * 0.15,
                    showTitle: false,
                    borderSide: const BorderSide(color: AppTheme.ink, width: 2),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppTheme.ink,
                  fontFamily: AppTheme.mono,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                centerBottom,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}