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