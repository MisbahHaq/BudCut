import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../currency.dart';
import '../models/transaction.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/progress.dart';
import 'modals.dart';

enum TxSort { dateDesc, dateAsc, amountDesc, amountAsc }

class TransactionList extends StatefulWidget {
  final AppState state;
  final List<AppTransaction>? fixedList;
  final DateTime? month;

  const TransactionList({
    super.key,
    required this.state,
    this.fixedList,
    this.month,
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  String _query = '';
  String? _categoryFilter;
  TxSort _sort = TxSort.dateDesc;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<AppTransaction> get _base {
    if (widget.fixedList != null) return widget.fixedList!;
    if (widget.month != null) {
      return widget.state.inRange(
        DateTime(widget.month!.year, widget.month!.month, 1),
        DateTime(widget.month!.year, widget.month!.month + 1, 0),
      );
    }
    return widget.state.transactions;
  }

  List<AppTransaction> _filtered() {
    var list = _base.where((t) {
      final cat = widget.state.categoryById(t.categoryId);
      final matchesCat =
          _categoryFilter == null || t.categoryId == _categoryFilter;
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          t.merchant.toLowerCase().contains(q) ||
          t.notes.toLowerCase().contains(q) ||
          (cat?.name.toLowerCase().contains(q) ?? false);
      return matchesCat && matchesQuery;
    }).toList();

    switch (_sort) {
      case TxSort.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TxSort.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TxSort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TxSort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  Future<void> _exportCsv() async {
    final cur = Currencies.current.value;
    final rows = <List<dynamic>>[
      ['Date', 'Merchant', 'Category', 'Amount', 'Currency', 'Tags', 'Notes'],
    ];
    for (final t in _base) {
      final cat = widget.state.categoryById(t.categoryId);
      rows.add([
        t.date.toIso8601String().substring(0, 10),
        t.merchant,
        cat?.name ?? t.categoryId,
        cur.fromPkr(t.amount).toDouble().toStringAsFixed(2),
        cur.code,
        t.tags.join('|'),
        t.notes,
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/budcut_export.csv');
      await file.writeAsBytes(utf8.encode(csv));
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'BudCut transaction export',
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Export prepared (${rows.length - 1} rows): ${csv.length} chars')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildControls(context),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 40, color: AppTheme.ink.withValues(alpha: .4)),
                const SizedBox(height: 8),
                Text('No transactions match',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
        else
          ...filtered.map((t) => _buildRow(context, t)),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search transactions…',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            BrutIconButton(
              icon: Icons.tune,
              tooltip: 'Sort & filter',
              onTap: () => _openSortSheet(context),
            ),
            const SizedBox(width: 8),
            BrutIconButton(
              icon: Icons.download,
              tooltip: 'Export CSV',
              onTap: _exportCsv,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All',
                selected: _categoryFilter == null,
                onTap: () => setState(() => _categoryFilter = null),
              ),
              for (final c in widget.state.categories)
                _FilterChip(
                  label: c.name,
                  selected: _categoryFilter == c.id,
                  onTap: () =>
                      setState(() => _categoryFilter = c.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SORT BY',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                for (final s in TxSort.values) _SortRow(label: _sortLabel(s), active: _sort == s, onTap: () {
                  setState(() => _sort = s);
                  Navigator.pop(ctx);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sortLabel(TxSort s) {
    switch (s) {
      case TxSort.dateDesc:
        return 'Newest first';
      case TxSort.dateAsc:
        return 'Oldest first';
      case TxSort.amountDesc:
        return 'Highest amount';
      case TxSort.amountAsc:
        return 'Lowest amount';
    }
  }

  Widget _buildRow(BuildContext context, AppTransaction t) {
    final cat = widget.state.categoryById(t.categoryId);
    final pastel = Color.lerp(ColorDot.parse(cat?.color ?? '#999999'),
        Colors.white, 0.6)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: AppTheme.border2(),
        boxShadow: [AppTheme.hardShadow(offset: 2)],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: pastel,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.ink, width: 1.5),
            ),
            child: Icon(Icons.receipt, size: 14, color: AppTheme.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.merchant.isEmpty ? cat?.name ?? '' : t.merchant,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (t.isRecurring) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.refresh, size: 12, color: AppTheme.ink),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat?.name ?? '?'}  ·  ${_fmtDate(t.date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money(t.amount).mon,
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniBtn(
                    icon: Icons.edit_outlined,
                    onTap: () async {
                      await openFullExpenseModal(context, widget.state,
                          existing: t);
                    },
                  ),
                  _MiniBtn(
                    icon: Icons.delete_outline,
                    color: AppTheme.negative,
                    onTap: () async {
                      final ok = await _confirmDelete(context, t);
                      if (ok == true) {
                        await widget.state.deleteTransaction(t.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppTransaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          '${t.merchant.isEmpty ? 'This transaction' : t.merchant} · '
          '${Money(t.amount).mon}',
        ),
        actions: [
          BrutButton(
            label: 'Cancel',
            color: AppTheme.white,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          const SizedBox(width: 8),
          BrutButton(
            label: 'Delete',
            color: AppTheme.rose,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _SortRow extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SortRow({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: active ? AppTheme.yellow : AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: AppTheme.border2(),
            ),
            width: double.infinity,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MiniBtn({
    required this.icon,
    required this.onTap,
    this.color = AppTheme.ink,
  });

  @override
  State<_MiniBtn> createState() => _MiniBtnState();
}

class _MiniBtnState extends State<_MiniBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(right: _down ? 1 : 2, bottom: _down ? 1 : 2),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.ink, width: 1.5),
            boxShadow: _down ? null : [AppTheme.hardShadow(offset: 1.5)],
          ),
          padding: const EdgeInsets.all(7),
          child: Icon(widget.icon, size: 15, color: widget.color),
        ),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          padding:
              EdgeInsets.only(right: _down ? 1 : 3, bottom: _down ? 1 : 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.selected ? AppTheme.ink : AppTheme.white,
              borderRadius: BorderRadius.circular(10),
              border: AppTheme.border2(),
              boxShadow: _down ? null : [AppTheme.hardShadow(offset: 2)],
            ),
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.3,
                color: widget.selected ? AppTheme.white : AppTheme.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}