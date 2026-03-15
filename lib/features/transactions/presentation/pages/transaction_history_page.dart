import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../dashboard/presentation/providers/providers.dart';
import '../../domain/entities/entities.dart';

class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      appBar: AppBar(title: const Text('記録')),
      body: transactions.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Belum ada transaksi', style: KakeiboTextStyles.labelLarge),
                  Text(DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
                      style: KakeiboTextStyles.bodyMedium),
                ],
              ),
            );
          }
          final grouped = <String, List<TransactionEntity>>{};
          for (final t in list) {
            final key = DateFormat('yyyy-MM-dd').format(t.date);
            grouped.putIfAbsent(key, () => []).add(t);
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: grouped.length,
            itemBuilder: (ctx, i) {
              final dateKey = grouped.keys.elementAt(i);
              final dayList = grouped[dateKey]!;
              return _DayGroup(date: DateTime.parse(dateKey), transactions: dayList, ref: ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionEntity> transactions;
  final WidgetRef ref;

  const _DayGroup({required this.date, required this.transactions, required this.ref});

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) return 'Hari Ini';
    final y = now.subtract(const Duration(days: 1));
    if (d.day == y.day && d.month == y.month && d.year == y.year) return 'Kemarin';
    return DateFormat('EEEE, d MMMM', 'id_ID').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final dayIncome = transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final dayExpense = transactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(children: [
            Text(_formatDate(date), style: KakeiboTextStyles.labelLarge),
            const Spacer(),
            if (dayIncome > 0)
              Text('+${dayIncome.toRupiah(compact: true)}',
                  style: KakeiboTextStyles.bodySmall.copyWith(color: KakeiboColors.income)),
            if (dayIncome > 0 && dayExpense > 0)
              Text(' · ', style: KakeiboTextStyles.bodySmall),
            if (dayExpense > 0)
              Text('-${dayExpense.toRupiah(compact: true)}',
                  style: KakeiboTextStyles.bodySmall.copyWith(color: KakeiboColors.expense)),
          ]),
        ),
        ...transactions.map((t) => _TransactionItem(transaction: t, ref: ref)),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionEntity transaction;
  final WidgetRef ref;

  const _TransactionItem({required this.transaction, required this.ref});

  @override
  Widget build(BuildContext context) {
    final config = transaction.categoryKakeiboType != null
        ? KakeiboTypeConfig.fromType(transaction.categoryKakeiboType!)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
      decoration: BoxDecoration(
        color: KakeiboColors.paperWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KakeiboColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: config?.lightColor ?? KakeiboColors.paper,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(config?.icon ?? Icons.category_outlined,
              color: config?.color ?? KakeiboColors.inkFade, size: 18),
        ),
        title: Text(
          transaction.categoryName ?? 'Tanpa Kategori',
          style: KakeiboTextStyles.bodyLarge.copyWith(fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note != null && transaction.note!.isNotEmpty)
              Text(transaction.note!, style: KakeiboTextStyles.bodySmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (config != null)
              Text(config.label,
                  style: KakeiboTextStyles.labelSmall.copyWith(color: config.color, fontSize: 9)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${transaction.isIncome ? '+' : '-'}${transaction.amount.toRupiah(compact: true)}',
                  style: KakeiboTextStyles.amountMedium(
                    color: transaction.isIncome ? KakeiboColors.income : KakeiboColors.expense,
                  ).copyWith(fontSize: 14),
                ),
                if (transaction.accountName != null)
                  Text(transaction.accountName!, style: KakeiboTextStyles.bodySmall),
              ],
            ),
            const SizedBox(width: 4),
            // Menu button - lebih reliable dari swipe di web
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: KakeiboColors.inkFade),
              onSelected: (v) {
                if (v == 'edit') _showEditSheet(context);
                if (v == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit'),
                ])),
                const PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: KakeiboColors.expense),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: KakeiboColors.expense)),
                ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          '${transaction.categoryName ?? "Transaksi"} sebesar '
          '${transaction.amount.toRupiah(compact: true)} akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: KakeiboColors.expense)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('transactions')
          .delete()
          .eq('id', transaction.id);
      ref.invalidate(monthlyTransactionsProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(kakeiboBreakdownProvider);
      ref.invalidate(accountsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KakeiboColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditTransactionSheet(transaction: transaction, ref: ref),
    );
  }
}

class _EditTransactionSheet extends StatefulWidget {
  final TransactionEntity transaction;
  final WidgetRef ref;
  const _EditTransactionSheet({required this.transaction, required this.ref});

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late final TextEditingController _noteCtrl;
  late final TextEditingController _amountCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.transaction.note ?? '');
    _amountCtrl = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('transactions').update({
        'amount': amount,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      }).eq('id', widget.transaction.id);
      widget.ref.invalidate(monthlyTransactionsProvider);
      widget.ref.invalidate(monthlySummaryProvider);
      widget.ref.invalidate(kakeiboBreakdownProvider);
      widget.ref.invalidate(accountsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.transaction.categoryKakeiboType != null
        ? KakeiboTypeConfig.fromType(widget.transaction.categoryKakeiboType!)
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit Transaksi',
                  style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (config != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: config.lightColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${config.label} · ${widget.transaction.categoryName ?? ""}',
                style: KakeiboTextStyles.labelSmall.copyWith(color: config.color),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Nominal', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: 'Rp '),
          ),
          const SizedBox(height: 12),
          Text('Catatan', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(hintText: 'Catatan (opsional)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}
