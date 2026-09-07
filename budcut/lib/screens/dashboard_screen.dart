import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/charts.dart';
import '../widgets/progress.dart';
import '../widgets/transaction_list.dart';

class DashboardScreen extends StatefulWidget {
  final AppState state;

  const DashboardScreen({super.key, required this.state});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final spend = state.spendInMonth(now);
    final budget = state.monthlyBudget;
    final remaining = budget - spend;
    final budgetFrac = (budget <= 0) ? 0.0 : (spend / budget).toDouble();

    final daysRemaining = lastDay.difference(now).inDays;
    final safeBurn = daysRemaining > 0
        ? (remaining / daysRemaining)
        : (remaining > 0 ? remaining : 0.0);

    final accumulatedDays = (now.day - 1) < 1 ? 1 : (now.day - 1);
    final avgDaily = accumulatedDays > 0
        ? (spend / accumulatedDays).toDouble()
        : 0.0;

    final daily = state.dailySpend(monthStart, now);
    final catSpend = state.spendByCategory(now);
    final donutSlices = <({String label, num value, Color color})>[
      for (final c in state.categories)
        if ((catSpend[c.id] ?? 0) > 0)
          (
            label: c.name,
            value: catSpend[c.id] ?? 0,
            color: ColorDot.parse(c.color),
          ),
    ];

    final monthTx = state.inRange(monthStart, lastDay);
    final displayed = monthTx.isNotEmpty ? monthTx : state.transactions;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: AppTheme.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          ScreenHeader(
            title: 'Dashboard',
            subtitle: 'Your money at a glance — ${_monthName(now)} ${now.year}',
          ),
          const SizedBox(height: 18),
          _kpiGrid(context, state, spend, budget, remaining, budgetFrac,
              safeBurn, avgDaily, daysRemaining),
          const SizedBox(height: 18),
          _analyticsSection(context, state, spend, budget, daily, catSpend,
              donutSlices),
          const SizedBox(height: 18),
          _categoryProgressSection(context, state, now, catSpend),
          const SizedBox(height: 18),
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECENT TRANSACTIONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                TransactionList(
                  state: state,
                  fixedList: displayed.take(15).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(
    BuildContext context,
    AppState state,
    num spend,
    num budget,
    num remaining,
    double budgetFrac,
    num safeBurn,
    num avgDaily,
    int daysRemaining,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoCol = width >= 480;
        final colW = twoCol ? (width - 12) / 2 : width;

        Widget cell(Widget child) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            );

        if (!twoCol) {
          return Column(
            children: [
              cell(SizedBox(
                  width: width,
                  child: _totalSpendCard(context, spend))),
              cell(SizedBox(
                  width: width,
                  child: _budgetCard(context, budget, spend, budgetFrac))),
              cell(SizedBox(
                  width: width,
                  child: _remainingCard(context, remaining))),
              cell(SizedBox(
                  width: width,
                  child: _averageCard(
                      context, avgDaily, daysRemaining, safeBurn))),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                    width: colW,
                    child: _totalSpendCard(context, spend)),
                const SizedBox(width: 12),
                SizedBox(
                    width: colW,
                    child: _remainingCard(context, remaining)),
              ],
            ),
            const SizedBox(height: 12),
            cell(SizedBox(
                width: width,
                child: _budgetCard(context, budget, spend, budgetFrac))),
            Row(
              children: [
                SizedBox(
                    width: colW,
                    child: _safeBurnCard(context, safeBurn, daysRemaining)),
                const SizedBox(width: 12),
                SizedBox(
                    width: colW,
                    child: _averageCard(
                        context, avgDaily, daysRemaining, safeBurn)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _totalSpendCard(BuildContext context, num spend) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileLabel('Total spend this month'),
          const SizedBox(height: 8),
          KpiValue(widget.state.formatValue(spend), size: 28),
        ],
      ),
    );
  }

  Widget _budgetCard(
    BuildContext context,
    num budget,
    num spend,
    double frac,
  ) {
    final over = spend > budget;
    return GestureDetector(
      onTap: () => _editBudget(context),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TileLabel('Monthly budget target'),
                Icon(Icons.edit_outlined, size: 14, color: AppTheme.inkSoft),
              ],
            ),
            const SizedBox(height: 8),
            KpiValue(widget.state.formatValue(budget), size: 22),
            const SizedBox(height: 12),
            ProgressBar(
              fraction: frac,
              color: over ? AppTheme.negative : AppTheme.ink,
              height: 12,
            ),
            const SizedBox(height: 6),
            Text(
              '${(frac * 100).toStringAsFixed(1)}% used',
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppTheme.mono,
                fontWeight: FontWeight.w800,
                color: over ? AppTheme.negative : AppTheme.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remainingCard(BuildContext context, num remaining) {
    final positive = remaining >= 0;
    return Container(
      decoration: BoxDecoration(
        color: positive ? AppTheme.surface : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
        boxShadow: const [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileLabel('Remaining safe buffer'),
          const SizedBox(height: 8),
          KpiValue(
            widget.state.formatValue(remaining),
            size: 24,
            color: positive ? AppTheme.positive : AppTheme.negative,
          ),
        ],
      ),
    );
  }

  Widget _safeBurnCard(BuildContext context, num safeBurn, int daysRemaining) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileLabel('Daily safe burn rate'),
          const SizedBox(height: 8),
          KpiValue(widget.state.formatValue(safeBurn), size: 22),
          const SizedBox(height: 4),
          Text(
            '$daysRemaining day(s) left this month',
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.inkSoft,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _averageCard(
    BuildContext context,
    num avgDaily,
    int daysRemaining,
    num safeBurn,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileLabel('Average daily spend'),
          const SizedBox(height: 8),
          KpiValue(widget.state.formatValue(avgDaily), size: 22),
          const SizedBox(height: 4),
          Text(
            avgDaily > safeBurn ? 'Above your safe burn' : 'Within safe burn',
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.inkSoft,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _analyticsSection(
    BuildContext context,
    AppState state,
    num spend,
    num budget,
    List<({DateTime day, num amount})> daily,
    Map<String, num> catSpend,
    List<({String label, num value, Color color})> donutSlices,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileLabel('Spending velocity — this month'),
          const SizedBox(height: 14),
          if (daily.length > 1)
            DailyBarChart(data: daily, maxLabels: 6)
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Not enough data yet',
                    style: TextStyle(
                        color: AppTheme.inkSoft,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          const SizedBox(height: 20),
          const TileLabel('Category distribution'),
          const SizedBox(height: 8),
          if (donutSlices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No spending recorded',
                    style: TextStyle(
                        color: AppTheme.inkSoft,
                        fontWeight: FontWeight.w600)),
              ),
            )
          else
            _donutRow(donutSlices),
        ],
      ),
    );
  }

  Widget _donutRow(
    List<({String label, num value, Color color})> slices,
  ) {
    final total = slices.fold<num>(0, (s, x) => s + x.value);
    return Row(
      children: [
        CategoryDonut(
          slices: slices,
          size: 160,
          centerTop: 'TOTAL',
          centerBottom: widget.state.formatValue(total),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < slices.length && i < 8; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slices[i].color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.ink, width: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slices[i].label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.inkSoft,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${((slices[i].value / total) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: AppTheme.mono,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryProgressSection(
    BuildContext context,
    AppState state,
    DateTime now,
    Map<String, num> catSpend,
  ) {
    final capped =
        state.categories.where((c) => c.monthlyCap != null).toList();

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileLabel('Category budget progress'),
          const SizedBox(height: 12),
          if (capped.isEmpty)
            const Text('No category caps set',
                style: TextStyle(
                    color: AppTheme.inkSoft, fontWeight: FontWeight.w600))
          else
            for (final c in capped)
              _categoryRow(context, c, catSpend[c.id] ?? 0),
        ],
      ),
    );
  }

  Widget _categoryRow(BuildContext context, dynamic c, num spent) {
    final cap = c.monthlyCap as num;
    final frac = spent / cap;
    final status = frac >= 1.0
        ? AppTheme.negative
        : frac >= 0.8
            ? AppTheme.warning
            : AppTheme.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorDot(c.color as String, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.name as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Text(
                widget.state.formatValue(spent),
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${widget.state.formatValue(cap)}',
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(
              fraction: frac.toDouble(), color: status, height: 8),
          const SizedBox(height: 3),
          Text(
            frac >= 1.0
                ? 'Over budget by ${widget.state.formatValue(spent - cap)}'
                : frac >= 0.8
                    ? 'Close to cap · ${((1 - frac) * 100).toStringAsFixed(0)}% left'
                    : '${(frac * 100).toStringAsFixed(0)}% of cap used',
            style: TextStyle(
              fontSize: 11,
              fontFamily: AppTheme.mono,
              fontWeight: FontWeight.w800,
              color: status,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(DateTime m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m.month - 1];
  }

  Future<void> _editBudget(BuildContext context) async {
    final controller =
        TextEditingController(text: '${widget.state.monthlyBudget}');
    final result = await showDialog<num>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EDIT MONTHLY BUDGET',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget',
                  prefixText: '${widget.state.currency.display} ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(
                        color: AppTheme.ink, width: AppTheme.borderWidth),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(
                        color: AppTheme.ink, width: AppTheme.borderWidth),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.ink,
                              width: AppTheme.borderWidth),
                        ),
                        child: const Center(
                          child: Text('CANCEL',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(
                          ctx,
                          num.tryParse(
                              controller.text.replaceAll(',', ''))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.ink,
                              width: AppTheme.borderWidth),
                          boxShadow: const [
                            BoxShadow(
                                offset: Offset(2, 2),
                                color: AppTheme.ink)
                          ],
                        ),
                        child: const Center(
                          child: Text('SAVE',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result > 0) {
      await widget.state.setMonthlyBudget(result);
    }
  }
}
