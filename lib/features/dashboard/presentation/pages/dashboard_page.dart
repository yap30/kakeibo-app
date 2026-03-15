import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../transactions/domain/entities/entities.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final breakdown = ref.watch(kakeiboBreakdownProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _DashboardHeader(
              profile: profile,
              selectedMonth: selectedMonth,
              onMonthChanged: (month) =>
                  ref.read(selectedMonthProvider.notifier).state = month,
            ),
          ),
          // Balance Card
          SliverToBoxAdapter(
            child: summary.when(
              data: (data) => _BalanceCard(summary: data),
              loading: () => _BalanceCardSkeleton(),
              error: (e, _) => const SizedBox(),
            ),
          ),
          // Kakeibo Breakdown
          SliverToBoxAdapter(
            child: breakdown.when(
              data: (data) => _KakeiboBreakdown(breakdown: data),
              loading: () => const _SectionSkeleton(),
              error: (e, _) => const SizedBox(),
            ),
          ),
          // Recent Transactions
          SliverToBoxAdapter(
            child: _RecentTransactionsHeader(
              onSeeAll: () => context.go('/history'),
            ),
          ),
          // Transaction List
          transactions.when(
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(child: _EmptyTransactions())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        if (i >= list.take(5).length) return null;
                        return _TransactionTile(transaction: list[i]);
                      },
                      childCount: list.take(5).length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(child: _SectionSkeleton()),
            error: (e, _) => const SliverToBoxAdapter(child: SizedBox()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _DashboardHeader extends StatelessWidget {
  final AsyncValue profile;
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const _DashboardHeader({
    required this.profile,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'かけいぼ',
                  style: KakeiboTextStyles.labelSmall.copyWith(
                    letterSpacing: 2,
                    color: KakeiboColors.inkFade,
                  ),
                ),
                const SizedBox(height: 2),
                profile.when(
                  data: (p) => Text(
                    'Halo, ${p?.displayName ?? 'Pengguna'}',
                    style: KakeiboTextStyles.displaySmall,
                  ),
                  loading: () => Container(
                    height: 22,
                    width: 140,
                    decoration: BoxDecoration(
                      color: KakeiboColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
          // Month selector
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: KakeiboColors.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KakeiboColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM yyyy', 'id_ID').format(selectedMonth),
                    style: KakeiboTextStyles.labelMedium,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 16, color: KakeiboColors.inkFade),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _MonthPickerSheet(
        selected: selectedMonth,
        onSelected: onMonthChanged,
      ),
    );
  }
}

// ============================================================
// BALANCE CARD
// ============================================================
class _BalanceCard extends StatelessWidget {
  final Map<String, double> summary;

  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final income = (summary['income'] ?? 0).toDouble();
    final expense = (summary['expense'] ?? 0).toDouble();
    final balance = (summary['balance'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KakeiboColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Bulan Ini',
            style: KakeiboTextStyles.labelSmall.copyWith(
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balance.toRupiah(),
            style: KakeiboTextStyles.amountLarge(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: 'Pemasukan',
                  amount: income,
                  icon: Icons.arrow_downward,
                  color: const Color(0xFF81C784),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: _BalanceItem(
                  label: 'Pengeluaran',
                  amount: expense,
                  icon: Icons.arrow_upward,
                  color: const Color(0xFFEF9A9A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: KakeiboTextStyles.labelSmall.copyWith(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount.toRupiah(compact: true),
            style: KakeiboTextStyles.amountMedium(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KAKEIBO BREAKDOWN
// ============================================================
class _KakeiboBreakdown extends StatelessWidget {
  final Map<String, double> breakdown;

  const _KakeiboBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0.0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KakeiboColors.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KakeiboColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Kategori Kakeibo', style: KakeiboTextStyles.labelLarge),
              const Spacer(),
              Text(
                total.toRupiah(compact: true),
                style: KakeiboTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          _KakeiboProgressBar(breakdown: breakdown, total: total),
          const SizedBox(height: 16),
          // Legend
          ...KakeiboTypeConfig.all.map((config) => _KakeiboLegendItem(
                config: config,
                amount: (breakdown[config.type] ?? 0).toDouble(),
                total: total,
              )),
        ],
      ),
    );
  }
}

class _KakeiboProgressBar extends StatelessWidget {
  final Map<String, double> breakdown;
  final double total;

  const _KakeiboProgressBar({required this.breakdown, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: KakeiboColors.divider,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: KakeiboTypeConfig.all.map((config) {
            final fraction = ((breakdown[config.type] ?? 0).toDouble()) / total;
            return Flexible(
              flex: (fraction * 100).round(),
              child: Container(color: config.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _KakeiboLegendItem extends StatelessWidget {
  final KakeiboTypeConfig config;
  final double amount;
  final double total;

  const _KakeiboLegendItem({
    required this.config,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (amount / total * 100).toStringAsFixed(0) : '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            config.kanji,
            style: KakeiboTextStyles.labelSmall.copyWith(
              fontFamily: 'Georgia',
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(config.label, style: KakeiboTextStyles.bodySmall),
          const Spacer(),
          Text(
            '$percent%',
            style: KakeiboTextStyles.labelSmall.copyWith(
              color: config.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(amount.toRupiah(compact: true), style: KakeiboTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================
// RECENT TRANSACTIONS
// ============================================================
class _RecentTransactionsHeader extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _RecentTransactionsHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text('Transaksi Terbaru', style: KakeiboTextStyles.labelLarge),
          const Spacer(),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'Lihat Semua',
              style: KakeiboTextStyles.bodySmall.copyWith(color: KakeiboColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final kakeiboConfig = transaction.categoryKakeiboType != null
        ? KakeiboTypeConfig.fromType(transaction.categoryKakeiboType!)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KakeiboColors.paperWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KakeiboColors.divider),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kakeiboConfig?.lightColor ?? KakeiboColors.paper,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              kakeiboConfig?.icon ?? Icons.category_outlined,
              color: kakeiboConfig?.color ?? KakeiboColors.inkFade,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.categoryName ?? 'Tanpa Kategori',
                  style: KakeiboTextStyles.bodyLarge.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  Text(
                    transaction.note!,
                    style: KakeiboTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Amount
          Text(
            '${transaction.isIncome ? '+' : '-'} ${transaction.amount.toDouble().toRupiah(compact: true)}',
            style: KakeiboTextStyles.amountMedium(
              color: transaction.isIncome ? KakeiboColors.income : KakeiboColors.expense,
            ).copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: KakeiboColors.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KakeiboColors.divider),
      ),
      child: Column(
        children: [
          const Text('家', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Belum ada transaksi', style: KakeiboTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Mulai catat pengeluaranmu hari ini',
            style: KakeiboTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Skeleton Loaders
class _BalanceCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 160,
      decoration: BoxDecoration(
        color: KakeiboColors.inkLight,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 100,
      decoration: BoxDecoration(
        color: KakeiboColors.divider,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final DateTime selected;
  final Function(DateTime) onSelected;

  const _MonthPickerSheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i, 1));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pilih Bulan', style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          ...months.map((month) => ListTile(
                title: Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(month),
                  style: KakeiboTextStyles.bodyLarge.copyWith(
                    fontWeight: month.month == selected.month && month.year == selected.year
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: month.month == selected.month && month.year == selected.year
                    ? const Icon(Icons.check, color: KakeiboColors.ink)
                    : null,
                onTap: () {
                  onSelected(month);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
