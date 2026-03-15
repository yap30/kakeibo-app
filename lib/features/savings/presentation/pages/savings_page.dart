import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../dashboard/presentation/providers/providers.dart';
import '../../../transactions/domain/entities/entities.dart';

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);

    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      appBar: AppBar(
        title: const Text('貯金'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalSheet(context, ref),
          ),
        ],
      ),
      body: goals.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏺', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text('Belum ada target tabungan', style: KakeiboTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Text('Buat target tabunganmu dan lacak kemajuannya',
                        style: KakeiboTextStyles.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _showAddGoalSheet(context, ref),
                      child: const Text('Tambah Target Tabungan'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            itemCount: list.length,
            itemBuilder: (ctx, i) => _SavingsGoalCard(
              goal: list[i],
              onEdit: () => _showEditGoalSheet(context, ref, list[i]),
              onDelete: () => _deleteGoal(context, ref, list[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KakeiboColors.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GoalSheet(ref: ref),
    );
  }

  void _showEditGoalSheet(BuildContext context, WidgetRef ref, SavingsGoalEntity goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KakeiboColors.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GoalSheet(ref: ref, goal: goal),
    );
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref, SavingsGoalEntity goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Target?'),
        content: Text('Target "${goal.name}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: KakeiboColors.expense)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.from('savings_goals').delete().eq('id', goal.id);
      ref.invalidate(savingsGoalsProvider);
    }
  }
}

class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoalEntity goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavingsGoalCard({required this.goal, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KakeiboColors.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goal.isCompleted ? KakeiboColors.needs : KakeiboColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: KakeiboColors.needsLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  goal.isCompleted ? Icons.check_circle : Icons.savings_outlined,
                  color: goal.isCompleted ? KakeiboColors.needs : KakeiboColors.inkFade,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: KakeiboTextStyles.labelLarge),
                    if (goal.isCompleted)
                      Text('✓ Tercapai!',
                          style: KakeiboTextStyles.bodySmall.copyWith(color: KakeiboColors.needs)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: KakeiboColors.inkFade),
                onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(
                    children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')],
                  )),
                  const PopupMenuItem(value: 'delete', child: Row(
                    children: [Icon(Icons.delete_outline, size: 16, color: KakeiboColors.expense),
                      SizedBox(width: 8), Text('Hapus', style: TextStyle(color: KakeiboColors.expense))],
                  )),
                ],
              ),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: KakeiboTextStyles.displaySmall.copyWith(
                      fontSize: 18, color: progress >= 1 ? KakeiboColors.needs : KakeiboColors.ink)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: KakeiboColors.paper,
              valueColor: AlwaysStoppedAnimation(progress >= 1 ? KakeiboColors.needs : KakeiboColors.ink),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(goal.currentAmount.toRupiah(compact: true),
                  style: KakeiboTextStyles.bodyMedium.copyWith(color: KakeiboColors.ink)),
              const Text(' / '),
              Text(goal.targetAmount.toRupiah(compact: true), style: KakeiboTextStyles.bodyMedium),
              const Spacer(),
              Text('Sisa: ${goal.remainingAmount.toRupiah(compact: true)}',
                  style: KakeiboTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  final WidgetRef ref;
  final SavingsGoalEntity? goal;
  const _GoalSheet({required this.ref, this.goal});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _currentController;
  bool _isSaving = false;
  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _amountController = TextEditingController(
        text: widget.goal != null ? widget.goal!.targetAmount.toStringAsFixed(0) : '');
    _currentController = TextEditingController(
        text: widget.goal != null ? widget.goal!.currentAmount.toStringAsFixed(0) : '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_amountController.text.replaceAll('.', ''));
    final current = double.tryParse(_currentController.text.replaceAll('.', '')) ?? 0;

    if (name.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi nama dan target jumlah')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = Supabase.instance.client;
      final profile = widget.ref.read(profileProvider).value;
      if (profile == null) throw Exception('Profile tidak ditemukan');

      if (_isEdit) {
        await client.from('savings_goals').update({
          'name': name,
          'target_amount': target,
          'current_amount': current,
          'is_completed': current >= target,
        }).eq('id', widget.goal!.id);
      } else {
        await client.from('savings_goals').insert({
          'profile_id': profile.id,
          'name': name,
          'target_amount': target,
          'current_amount': current,
          'icon': 'savings',
          'color': '#2A9D8F',
          'is_completed': current >= target,
        });
      }

      widget.ref.invalidate(savingsGoalsProvider);
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
              Text(_isEdit ? 'Edit Target' : 'Target Tabungan Baru',
                  style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Nama Target', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Contoh: Liburan ke Bali'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Text('Target Jumlah (Rp)', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '5000000', prefixText: 'Rp '),
          ),
          const SizedBox(height: 12),
          Text('Tabungan Saat Ini (Rp)', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _currentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '0', prefixText: 'Rp '),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Target'),
          ),
        ],
      ),
    );
  }
}
