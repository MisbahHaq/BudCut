import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/progress.dart';

const _palette = [
  '#E5484D', '#F5A623', '#30A46C', '#1498D8', '#7C6AF0',
  '#EC5CA8', '#3E63DD', '#8A4AF0', '#EE6C4D', '#1BA19D',
  '#9A3412', '#0F766E', '#334155', '#B45309',
];

class CategoryManagerScreen extends StatelessWidget {
  final AppState state;

  const CategoryManagerScreen({super.key, required this.state});

  void _openEditor(BuildContext context, CategoryModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: _CategoryEditor(state: state, existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        const ScreenHeader(
          title: 'Budgets & Categories',
          subtitle: 'Set your targets and manage categories',
        ),
        const SizedBox(height: 16),
        _BudgetCard(state: state),
        const SizedBox(height: 18),
        const Text('CATEGORIES',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: AppTheme.ink)),
        const SizedBox(height: 8),
        for (final c in state.categories) _categoryTile(context, c),
        const SizedBox(height: 12),
        Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: InkWell(
            onTap: () => _openEditor(context, null),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                    color: AppTheme.ink, width: AppTheme.borderWidth),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: AppTheme.ink),
                  SizedBox(width: 6),
                  Text('ADD CATEGORY',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.ink,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        BrutButton(
          label: 'Reset All Data',
          icon: Icons.delete_forever_outlined,
          color: AppTheme.rose,
          onPressed: () => _confirmReset(context),
        ),
        const SizedBox(height: 12),
        const Text(
          'Clears transactions, bills, categories and budget to zero.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.inkSoft),
        ),
        const SizedBox(height: 18),
        BrutButton(
          label: 'Sign out',
          icon: Icons.logout,
          color: AppTheme.surfaceAlt,
          textColor: AppTheme.ink,
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'Deletes every transaction, bill and category and sets the '
          'budget to 0. This cannot be undone.',
        ),
        actions: [
          BrutButton(
            label: 'Cancel',
            color: AppTheme.white,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          const SizedBox(width: 8),
          BrutButton(
            label: 'Reset',
            color: AppTheme.rose,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared — fresh start')),
        );
      }
    }
  }

  Widget _categoryTile(BuildContext context, CategoryModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          ColorDot(c.color, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppTheme.ink),
                    ),
                    if (c.isFixed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.lavender,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.ink, width: 1),
                        ),
                        child: const Text('FIXED',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: AppTheme.ink)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.monthlyCap != null
                      ? 'Cap ${state.formatValue(c.monthlyCap!)}'
                      : 'No cap set',
                  style: const TextStyle(
                    fontFamily: AppTheme.mono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          _MiniBtn(
            icon: Icons.delete_outline,
            color: AppTheme.negative,
            onTap: () => _confirmDelete(context, c),
          ),
          _MiniBtn(
            icon: Icons.edit_outlined,
            onTap: () => _openEditor(context, c),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DELETE CATEGORY?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(
                'Delete category "${c.name}"? Existing transactions keep their category reference.',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
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
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.negative,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.ink,
                              width: AppTheme.borderWidth),
                        ),
                        child: const Center(
                          child: Text('DELETE',
                              style: TextStyle(
                                  color: Colors.white,
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
    if (ok == true) await state.deleteCategory(c.id);
  }
}

class _BudgetCard extends StatelessWidget {
  final AppState state;
  const _BudgetCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spend = state.spendInMonth(now);
    final budget = state.monthlyBudget;
    final frac = budget > 0 ? (spend / budget).toDouble() : 0.0;

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
                TileLabel('Monthly budget ceiling'),
                Icon(Icons.edit_outlined, size: 14, color: AppTheme.inkSoft),
              ],
            ),
            const SizedBox(height: 8),
            KpiValue(state.formatValue(budget), size: 26),
            const SizedBox(height: 12),
            ProgressBar(
              fraction: frac,
              color: frac >= 1 ? AppTheme.negative : AppTheme.ink,
              height: 12,
            ),
            const SizedBox(height: 6),
            Text(
              '${state.formatValue(spend)} spent (${(frac * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontFamily: AppTheme.mono,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudget(BuildContext context) async {
    final controller = TextEditingController(text: '${state.monthlyBudget}');
    final result = await showDialog<num>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MONTHLY BUDGET CEILING',
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
                  prefixText: '${state.currency.display} ',
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
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
                          ctx, num.tryParse(controller.text)),
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
      await state.setMonthlyBudget(result);
    }
  }
}

class _CategoryEditor extends StatefulWidget {
  final AppState state;
  final CategoryModel? existing;
  const _CategoryEditor({required this.state, this.existing});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController _name;
  late final TextEditingController _cap;
  String _color = _palette.first;
  bool _isFixed = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _cap = TextEditingController(
        text: e?.monthlyCap != null ? '${e!.monthlyCap}' : '');
    _color = e?.color ?? _palette.first;
    _isFixed = e?.isFixed ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _cap.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a category name')),
      );
      return;
    }
    final cap = num.tryParse(_cap.text.replaceAll(',', ''));
    final name = _name.text.trim();
    if (widget.existing != null) {
      widget.state.updateCategory(widget.existing!.copyWith(
        name: name,
        color: _color,
        monthlyCap: (cap == null || cap <= 0) ? null : cap,
        isFixed: _isFixed,
      ));
    } else {
      widget.state.addCategory(
        name,
        _color,
        monthlyCap: (cap == null || cap <= 0) ? null : cap,
        isFixed: _isFixed,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'NEW CATEGORY' : 'EDIT CATEGORY',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _inputField(_name, 'Category name', Icons.sell_outlined),
          const SizedBox(height: 12),
          _inputField(_cap, 'Monthly cap', Icons.track_changes,
              showCurrencyPrefix: true),
          const SizedBox(height: 16),
          const Text('COLOR',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hex in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorDot.parse(hex),
                          border: Border.all(
                            color: AppTheme.ink,
                            width: _color == hex
                                ? AppTheme.borderWidth
                                : 1,
                          ),
                        ),
                        child: _color == hex
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border:
                  Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
            ),
            child: Row(
              children: [
                const Expanded(
                    child: Text('FIXED / COMMITTED',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink))),
                Switch(
                  value: _isFixed,
                  activeTrackColor: AppTheme.accent,
                  onChanged: (v) => setState(() => _isFixed = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: BrutalistButton(
              label: widget.existing == null
                  ? 'Create Category'
                  : 'Save Changes',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {bool showCurrencyPrefix = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: showCurrencyPrefix
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: showCurrencyPrefix ? 'Optional' : hint,
        labelText: hint,
        prefixText: showCurrencyPrefix
            ? '${widget.state.currency.display} '
            : null,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide:
              const BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide:
              const BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide:
              const BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MiniBtn({
    required this.icon,
    required this.onTap,
    this.color = AppTheme.inkSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.ink, width: 1.5),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
