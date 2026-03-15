import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../domain/entities/entities.dart';
import '../../../dashboard/presentation/providers/providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});
  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  String _type = 'expense';
  String _amountStr = '';
  String? _selectedCategoryId;
  String? _selectedAccountId;
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountStr) ?? 0;

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      } else if (key == '000') {
        if (_amountStr.length < 12) _amountStr += '000';
      } else {
        if (_amountStr.length < 12) _amountStr += key;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: KakeiboColors.ink,
            onPrimary: Colors.white,
            surface: KakeiboColors.paperWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal transaksi')));
      return;
    }
    final profile = ref.read(profileProvider).value;
    final accounts = ref.read(accountsProvider).value ?? [];
    final accountId = _selectedAccountId
        ?? accounts.firstWhereOrNull((a) => a.isDefault)?.id
        ?? (accounts.isNotEmpty ? accounts.first.id : null);

    if (accountId == null || profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setup akun terlebih dahulu')));
      return;
    }
    await ref.read(addTransactionProvider.notifier).addTransaction(
      accountId: accountId,
      profileId: profile.id,
      type: _type,
      amount: _amount,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: _selectedDate,
    );
    if (mounted) {
      final state = ref.read(addTransactionProvider);
      if (state.success) {
        HapticFeedback.mediumImpact();
        context.pop();
      } else if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final accounts = ref.watch(accountsProvider).value ?? [];
    final addState = ref.watch(addTransactionProvider);
    final filteredCategories = _type == 'expense'
        ? categories
        : categories.where((c) => c.kakeiboType == 'income').toList();

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      final defaultAcc = accounts.firstWhereOrNull((a) => a.isDefault);
      _selectedAccountId = defaultAcc?.id ?? accounts.first.id;
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: KakeiboColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close, color: KakeiboColors.ink)),
                    Text('Tambah Transaksi', style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
                  ],
                ),
              ),
              // Type Toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: KakeiboColors.paperWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KakeiboColors.divider),
                ),
                child: Row(
                  children: [
                    _buildTypeChip('Pengeluaran', Icons.arrow_upward, 'expense', KakeiboColors.expense),
                    _buildTypeChip('Pemasukan', Icons.arrow_downward, 'income', KakeiboColors.income),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Amount
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text('Rp', style: KakeiboTextStyles.bodyMedium.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      _amount == 0 ? '0' : _amount.toRupiah(showSymbol: false),
                      style: KakeiboTextStyles.amountLarge(
                        color: _amount == 0 ? KakeiboColors.inkFade
                            : (_type == 'income' ? KakeiboColors.income : KakeiboColors.expense),
                      ).copyWith(fontSize: 30),
                    ),
                  ],
                ),
              ),
              // Categories
              if (filteredCategories.isNotEmpty)
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final cat = filteredCategories[i];
                      final config = KakeiboTypeConfig.fromType(cat.kakeiboType);
                      final isSelected = cat.id == _selectedCategoryId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = isSelected ? null : cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? config.color : KakeiboColors.paperWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? config.color : KakeiboColors.divider),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(config.icon, size: 16, color: isSelected ? Colors.white : config.color),
                              const SizedBox(height: 2),
                              Text(
                                cat.name.length > 8 ? '${cat.name.substring(0, 7)}…' : cat.name,
                                style: KakeiboTextStyles.labelSmall.copyWith(
                                  color: isSelected ? Colors.white : KakeiboColors.ink,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 4),
              // Account & Date Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Account dropdown
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showAccountPicker(context, accounts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: KakeiboColors.paperWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: KakeiboColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, size: 14, color: KakeiboColors.inkFade),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  accounts.firstWhereOrNull((a) => a.id == _selectedAccountId)?.name ?? 'Pilih Akun',
                                  style: KakeiboTextStyles.labelMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.expand_more, size: 14, color: KakeiboColors.inkFade),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date button
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: KakeiboColors.paperWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: KakeiboColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: KakeiboColors.inkFade),
                            const SizedBox(width: 6),
                            Text(_formatDate(_selectedDate), style: KakeiboTextStyles.labelMedium),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Catatan (opsional)',
                    prefixIcon: Icon(Icons.edit_outlined, size: 16),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: KakeiboTextStyles.bodyLarge.copyWith(fontSize: 14),
                ),
              ),
              const Spacer(),
              // Numpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ['1','2','3'],
                    ['4','5','6'],
                    ['7','8','9'],
                    ['000','0','⌫'],
                  ].map((row) => Row(
                    children: row.map((key) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: InkWell(
                          onTap: () => _onKeyPress(key),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: KakeiboColors.paperWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: KakeiboColors.divider),
                            ),
                            child: Center(
                              child: key == '⌫'
                                  ? const Icon(Icons.backspace_outlined, size: 17, color: KakeiboColors.ink)
                                  : Text(key, style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 17)),
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Submit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: addState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
                  child: addState.isLoading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_type == 'expense' ? 'Catat Pengeluaran' : 'Catat Pemasukan'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, String value, Color color) {
    final isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _type = value; _selectedCategoryId = null; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : KakeiboColors.inkFade),
              const SizedBox(width: 5),
              Text(label, style: KakeiboTextStyles.labelMedium.copyWith(color: isSelected ? Colors.white : KakeiboColors.inkFade)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Hari Ini';
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  void _showAccountPicker(BuildContext context, List<AccountEntity> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KakeiboColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Akun', style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            ...accounts.map((a) => ListTile(
              leading: Icon(
                a.type == 'bank' ? Icons.account_balance_outlined
                    : a.type == 'e-wallet' ? Icons.phone_android_outlined
                    : Icons.money_outlined,
                color: KakeiboColors.inkFade,
              ),
              title: Text(a.name, style: KakeiboTextStyles.bodyLarge),
              subtitle: Text(a.balance.toRupiah(compact: true), style: KakeiboTextStyles.bodySmall),
              trailing: a.id == _selectedAccountId ? const Icon(Icons.check, color: KakeiboColors.ink) : null,
              onTap: () { setState(() => _selectedAccountId = a.id); Navigator.pop(context); },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) { if (test(element)) return element; }
    return null;
  }
}
