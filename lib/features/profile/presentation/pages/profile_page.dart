import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../dashboard/presentation/providers/providers.dart';
import '../../../transactions/domain/entities/entities.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      appBar: AppBar(title: const Text('プロフィール')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          profile.when(
            data: (p) => _ProfileCard(
              name: p?.displayName ?? 'Pengguna',
              email: p?.email ?? '',
              monthlyBudget: p?.monthlyBudget ?? 0,
            ),
            loading: () => const _CardSkeleton(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Akun Keuangan', style: KakeiboTextStyles.labelLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAccountSheet(context, ref, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
                style: TextButton.styleFrom(foregroundColor: KakeiboColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          accounts.when(
            data: (list) => list.isEmpty
                ? _EmptyAccountCard(onAdd: () => _showAccountSheet(context, ref, null))
                : Column(
                    children: [
                      ...list.map((a) => _AccountTile(
                            account: a,
                            onEdit: () => _showAccountSheet(context, ref, a),
                            onDelete: () => _deleteAccount(context, ref, a),
                            onSetDefault: () => _setDefault(ref, a),
                          )),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showAccountSheet(context, ref, null),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Akun Baru'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KakeiboColors.ink,
                          side: const BorderSide(color: KakeiboColors.divider),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
            loading: () => const _CardSkeleton(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          Text('Pengaturan', style: KakeiboTextStyles.labelLarge),
          const SizedBox(height: 12),
          _SettingTile(
            icon: Icons.info_outline,
            label: 'Tentang Kakeibo',
            subtitle: 'Metode budgeting dari Jepang',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, size: 16, color: KakeiboColors.expense),
            label: const Text('Keluar', style: TextStyle(color: KakeiboColors.expense)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: KakeiboColors.expense),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 32),
          Center(child: Text('Kakeibo v1.0.0 · 家計簿', style: KakeiboTextStyles.bodySmall)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref, AccountEntity? account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KakeiboColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccountSheet(ref: ref, account: account),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref, AccountEntity account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Text('Akun "${account.name}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: KakeiboColors.expense)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('accounts')
          .delete()
          .eq('id', account.id);
      ref.invalidate(accountsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  Future<void> _setDefault(WidgetRef ref, AccountEntity account) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    await client.from('accounts').update({'is_default': false}).eq('profile_id', userId);
    await client.from('accounts').update({'is_default': true}).eq('id', account.id);
    ref.invalidate(accountsProvider);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar', style: TextStyle(color: KakeiboColors.expense)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KakeiboColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('家計簿', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('Kakeibo (家計簿)', style: KakeiboTextStyles.displaySmall),
            const SizedBox(height: 12),
            Text(
              'Kakeibo adalah metode budgeting Jepang yang diciptakan oleh Hani Motoko pada 1904. '
              'Metode ini mengajarkan kita untuk sadar penuh terhadap pengeluaran dengan mencatat '
              'setiap transaksi ke dalam 4 kategori utama dan melakukan refleksi mingguan.',
              style: KakeiboTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Account Tile ──────────────────────────────────────────────
class _AccountTile extends StatelessWidget {
  final AccountEntity account;
  final VoidCallback onEdit, onDelete, onSetDefault;

  const _AccountTile({
    required this.account,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final icons = {
      'cash': Icons.money_outlined,
      'bank': Icons.account_balance_outlined,
      'e-wallet': Icons.phone_android_outlined,
      'credit': Icons.credit_card_outlined,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KakeiboColors.paperWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: account.isDefault ? KakeiboColors.needs : KakeiboColors.divider,
          width: account.isDefault ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: account.isDefault ? KakeiboColors.needsLight : KakeiboColors.paper,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icons[account.type] ?? Icons.wallet_outlined,
            color: account.isDefault ? KakeiboColors.needs : KakeiboColors.inkFade,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(child: Text(account.name, style: KakeiboTextStyles.bodyLarge.copyWith(fontSize: 14))),
            if (account.isDefault) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: KakeiboColors.needsLight, borderRadius: BorderRadius.circular(4)),
                child: Text('Utama', style: KakeiboTextStyles.labelSmall.copyWith(color: KakeiboColors.needs, fontSize: 9)),
              ),
            ],
          ],
        ),
        subtitle: Text(account.balance.toRupiah(compact: true), style: KakeiboTextStyles.bodySmall),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: KakeiboColors.inkFade),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
            if (v == 'default') onSetDefault();
          },
          itemBuilder: (_) => [
            if (!account.isDefault)
              const PopupMenuItem(value: 'default', child: Row(children: [
                Icon(Icons.star_outline, size: 16), SizedBox(width: 8), Text('Set Utama'),
              ])),
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
      ),
    );
  }
}

// ── Add / Edit Account Sheet ──────────────────────────────────
class _AccountSheet extends StatefulWidget {
  final WidgetRef ref;
  final AccountEntity? account;
  const _AccountSheet({required this.ref, this.account});

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late String _type;
  bool _isSaving = false;
  bool get _isEdit => widget.account != null;

  final _types = [
    {'value': 'cash', 'label': 'Tunai'},
    {'value': 'bank', 'label': 'Bank'},
    {'value': 'e-wallet', 'label': 'E-Wallet'},
    {'value': 'credit', 'label': 'Kredit'},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.account != null ? widget.account!.balance.toStringAsFixed(0) : '',
    );
    _type = widget.account?.type ?? 'bank';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text.replaceAll('.', '')) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama akun tidak boleh kosong')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final profile = widget.ref.read(profileProvider).value;
      if (profile == null) throw Exception('Profile tidak ditemukan');

      if (_isEdit) {
        await client.from('accounts').update({'name': name, 'type': _type, 'balance': balance})
            .eq('id', widget.account!.id);
      } else {
        final accounts = widget.ref.read(accountsProvider).value ?? [];
        await client.from('accounts').insert({
          'profile_id': profile.id,
          'name': name,
          'type': _type,
          'balance': balance,
          'color': '#4A90E2',
          'icon': 'wallet',
          'is_default': accounts.isEmpty,
        });
      }
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
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_isEdit ? 'Edit Akun' : 'Tambah Akun', style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 20)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Tipe Akun', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: _types.map((t) {
              final isSel = t['value'] == _type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? KakeiboColors.ink : KakeiboColors.paperWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSel ? KakeiboColors.ink : KakeiboColors.divider),
                    ),
                    child: Center(child: Text(t['label']!, style: KakeiboTextStyles.labelSmall.copyWith(color: isSel ? Colors.white : KakeiboColors.ink))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Nama Akun', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'BCA, GoPay, Dompet...')),
          const SizedBox(height: 12),
          Text(_isEdit ? 'Update Saldo' : 'Saldo Awal', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(controller: _balanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '1000000', prefixText: 'Rp ')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isEdit ? 'Simpan' : 'Tambah Akun'),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyAccountCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAccountCard({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: KakeiboColors.paperWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: KakeiboColors.divider)),
    child: Column(children: [
      const Icon(Icons.account_balance_wallet_outlined, size: 40, color: KakeiboColors.inkFade),
      const SizedBox(height: 12),
      Text('Belum ada akun keuangan', style: KakeiboTextStyles.labelLarge),
      const SizedBox(height: 4),
      Text('Tambahkan akun bank, dompet, atau e-wallet', style: KakeiboTextStyles.bodySmall, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 16), label: const Text('Tambah Akun')),
    ]),
  );
}

// ── Profile Card ───────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String name, email;
  final double monthlyBudget;
  const _ProfileCard({required this.name, required this.email, required this.monthlyBudget});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: KakeiboColors.paperWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: KakeiboColors.divider)),
    child: Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: KakeiboColors.ink, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700),
        )),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
        Text(email, style: KakeiboTextStyles.bodySmall),
        if (monthlyBudget > 0) ...[
          const SizedBox(height: 2),
          Text('Budget: ${monthlyBudget.toRupiah(compact: true)}/bulan', style: KakeiboTextStyles.bodySmall.copyWith(color: KakeiboColors.needs)),
        ],
      ])),
    ]),
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: KakeiboColors.divider)),
      tileColor: KakeiboColors.paperWhite,
      leading: Icon(icon, color: KakeiboColors.inkFade, size: 20),
      title: Text(label, style: KakeiboTextStyles.bodyLarge.copyWith(fontSize: 14)),
      subtitle: Text(subtitle, style: KakeiboTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 18, color: KakeiboColors.inkFade),
    ),
  );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    decoration: BoxDecoration(color: KakeiboColors.divider, borderRadius: BorderRadius.circular(16)),
  );
}
