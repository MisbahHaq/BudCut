import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../currency.dart';
import '../models/transaction.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'bento.dart';
import 'progress.dart';

const quickAmounts = <int>[100, 250, 500, 1000, 1500, 2500, 5000];

/// Opens the sub-5-second quick-add modal.
Future<void> openQuickAddModal(BuildContext context, AppState state) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: _QuickAddSheet(state: state),
    ),
  );
}

class _QuickAddSheet extends StatefulWidget {
  final AppState state;
  const _QuickAddSheet({required this.state});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  String? _categoryId;
  final String _notes = '';

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  void _submit() {
    final amt = num.tryParse(_amount.text.replaceAll(',', ''));
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final cat = _categoryId;
    if (cat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category')),
      );
      return;
    }
    final cur = Currencies.current.value;
    widget.state.addTransaction(
      amount: cur.toPkr(amt),
      date: DateTime.now(),
      categoryId: cat,
      merchant: _merchant.text.trim(),
      notes: _notes,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cur = Currencies.current.value;
    final now = DateTime.now();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.yellow,
                  border: AppTheme.border2(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'QUICK ADD',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppTheme.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${now.day}/${now.month}/${now.year}',
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BentoCard(
            padding: const EdgeInsets.all(14),
            color: AppTheme.yellowSoft,
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.mono,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '${cur.symbol} ',
                helperText: '',
                filled: false,
                hintStyle: const TextStyle(
                  fontFamily: AppTheme.mono,
                  color: AppTheme.inkSoft,
                ),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final a in quickAmounts)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _AmountChip(
                      label: '${cur.symbol} ${_groupNumber(a)}',
                      onTap: () => setState(() => _amount.text = '$a'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const TileLabel('Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in widget.state.categories)
                _CategoryChip(
                  name: c.name,
                  colorHex: c.color,
                  selected: _categoryId == c.id,
                  onTap: () => setState(() => _categoryId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchant,
            decoration: const InputDecoration(
              hintText: 'Merchant / note (optional)',
              prefixIcon: Icon(Icons.storefront_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: BrutButton(
              label: 'Log Expense',
              icon: Icons.add,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

String _groupNumber(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  var out = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  while (rest.length > 2) {
    out = '${rest.substring(rest.length - 2)},$out';
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) out = '$rest,$out';
  return out;
}

/// Formats an amount in the active currency for the edit field (no symbol).
String _amountLabel(num value) {
  final v = value;
  final asDouble = v.toDouble();
  if (asDouble == asDouble.roundToDouble()) return asDouble.toInt().toString();
  return asDouble.toStringAsFixed(2);
}

class _AmountChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AmountChip({required this.label, required this.onTap});

  @override
  State<_AmountChip> createState() => _AmountChipState();
}

class _AmountChipState extends State<_AmountChip> {
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
        padding: EdgeInsets.only(right: _down ? 1 : 3, bottom: _down ? 1 : 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: AppTheme.border2(),
            boxShadow: _down ? null : [AppTheme.hardShadow(offset: 2)],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: AppTheme.mono,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String name;
  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _down = false;

  Color get _pastel {
    final c = ColorDot.parse(widget.colorHex);
    return Color.lerp(c, Colors.white, 0.62)!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(right: _down ? 1 : 3, bottom: _down ? 1 : 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected ? _pastel : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: AppTheme.border2(),
            boxShadow: _down ? null : [AppTheme.hardShadow(offset: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ColorDot.parse(widget.colorHex),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.ink, width: 1.5),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the full expense editor (create or edit).
Future<void> openFullExpenseModal(
  BuildContext context,
  AppState state, {
  AppTransaction? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: _FullExpenseSheet(state: state, existing: existing),
    ),
  );
}

class _FullExpenseSheet extends StatefulWidget {
  final AppState state;
  final AppTransaction? existing;

  const _FullExpenseSheet({required this.state, this.existing});

  @override
  State<_FullExpenseSheet> createState() => _FullExpenseSheetState();
}

class _FullExpenseSheetState extends State<_FullExpenseSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _merchant;
  late final TextEditingController _tags;
  late final TextEditingController _notes;
  DateTime _date;
  String? _categoryId;
  bool _recurring;

  _FullExpenseSheetState()
      : _date = DateTime.now(),
        _recurring = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final cur = Currencies.current.value;
    _amount = TextEditingController(
      text: e != null ? _amountLabel(cur.fromPkr(e.amount)) : '',
    );
    _merchant = TextEditingController(text: e?.merchant ?? '');
    _tags = TextEditingController(text: e?.tags.join(', ') ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId;
    _recurring = e?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _tags.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amt = num.tryParse(_amount.text.replaceAll(',', ''));
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final cat = _categoryId;
    if (cat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category')),
      );
      return;
    }
    final tags = _tags.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final cur = Currencies.current.value;

    if (widget.existing != null) {
      widget.state.updateTransaction(widget.existing!.copyWith(
        amount: cur.toPkr(amt),
        date: _date,
        categoryId: cat,
        merchant: _merchant.text.trim(),
        notes: _notes.text.trim(),
        tags: tags,
        isRecurring: _recurring,
      ));
    } else {
      widget.state.addTransaction(
        amount: cur.toPkr(amt),
        date: _date,
        categoryId: cat,
        merchant: _merchant.text.trim(),
        notes: _notes.text.trim(),
        tags: tags,
        isRecurring: _recurring,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.existing;
    final cur = Currencies.current.value;
    final cat = _categoryId != null
        ? widget.state.categoryById(_categoryId!)
        : null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.lavender,
                  border: AppTheme.border2(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                e == null ? 'NEW EXPENSE' : 'EDIT EXPENSE',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BentoCard(
            padding: const EdgeInsets.all(14),
            color: AppTheme.yellowSoft,
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.mono,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '${cur.symbol} ',
                filled: false,
                hintStyle: const TextStyle(
                  fontFamily: AppTheme.mono,
                  color: AppTheme.inkSoft,
                ),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const TileLabel('Category'),
          const SizedBox(height: 6),
          DropdownButtonFormField<CategoryOption>(
            initialValue: cat != null ? CategoryOption(cat.id, cat.name) : null,
            isExpanded: true,
            items: [
              for (final c in widget.state.categories)
                DropdownMenuItem(
                  value: CategoryOption(c.id, c.name),
                  child: Row(
                    children: [
                      ColorDot(c.color, size: 8),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name)),
                      if (c.monthlyCap != null) ...[
                        const SizedBox(width: 8),
                        Text('CAP ${Money(c.monthlyCap!).mon}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontFamily: AppTheme.mono,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkSoft)),
                      ],
                    ],
                  ),
                ),
            ],
            onChanged: (o) => setState(() => _categoryId = o?.id),
            hint: const Text('Select category',
                style: TextStyle(color: AppTheme.inkSoft)),
          ),
          const SizedBox(height: 14),
          _dateRow(context),
          const SizedBox(height: 14),
          TextField(
            controller: _merchant,
            decoration: const InputDecoration(
              hintText: 'Merchant / Payee',
              prefixIcon: Icon(Icons.storefront_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              hintText: 'Tags (comma-separated)',
              prefixIcon: Icon(Icons.label_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Notes',
              prefixIcon: Icon(Icons.notes, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          _RecurringToggle(
            value: _recurring,
            onChanged: (v) => setState(() => _recurring = v),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: BrutButton(
                  label: e == null ? 'Save Expense' : 'Update',
                  icon: Icons.save_outlined,
                  color: AppTheme.yellow,
                  onPressed: _submit,
                ),
              ),
              if (e != null) ...[
                const SizedBox(width: 10),
                BrutButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: AppTheme.rose,
                  onPressed: () => _confirmDelete(context, e),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppTransaction e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text(
          '${e.merchant.isEmpty ? 'This transaction' : e.merchant} · '
          '${Money(e.amount).mon}. This cannot be undone.',
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
    if (ok == true) {
      await widget.state.deleteTransaction(e.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _dateRow(BuildContext context) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: AppTheme.border2(),
          boxShadow: [AppTheme.hardShadow(offset: 2)],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppTheme.ink),
            const SizedBox(width: 10),
            Text(
              '${_date.day}/${_date.month}/${_date.year}',
              style: const TextStyle(
                fontFamily: AppTheme.mono,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RecurringToggle({required this.value, required this.onChanged});

  @override
  State<_RecurringToggle> createState() => _RecurringToggleState();
}

class _RecurringToggleState extends State<_RecurringToggle> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(right: _down ? 1 : 3, bottom: _down ? 1 : 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: widget.value ? AppTheme.mint : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: AppTheme.border2(),
            boxShadow: _down ? null : [AppTheme.hardShadow(offset: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.value
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: AppTheme.ink,
              ),
              const SizedBox(width: 8),
              Text(
                'MARK AS RECURRING',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryOption {
  final String id;
  final String name;
  const CategoryOption(this.id, this.name);
}