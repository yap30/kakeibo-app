import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../dashboard/presentation/providers/providers.dart';
import '../../../transactions/domain/entities/entities.dart';

class ReflectionPage extends ConsumerStatefulWidget {
  const ReflectionPage({super.key});

  @override
  ConsumerState<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends ConsumerState<ReflectionPage> {
  final _whatEarnedController = TextEditingController();
  final _whatSpentController = TextEditingController();
  final _improveController = TextEditingController();
  final _savingsNoteController = TextEditingController();
  int? _moodScore;
  bool _isSaving = false;

  @override
  void dispose() {
    _whatEarnedController.dispose();
    _whatSpentController.dispose();
    _improveController.dispose();
    _savingsNoteController.dispose();
    super.dispose();
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile tidak ditemukan. Coba login ulang.')));
      return;
    }

    final summary = ref.read(monthlySummaryProvider).value ??
        {'income': 0.0, 'expense': 0.0, 'balance': 0.0};

    setState(() => _isSaving = true);

    try {
      final weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
      final weekEnd = weekStart.add(const Duration(days: 6));

      await Supabase.instance.client.from('weekly_reflections').upsert({
        'profile_id': profile.id,
        'week_start_date': weekStart.toIso8601String().split('T')[0],
        'week_end_date': weekEnd.toIso8601String().split('T')[0],
        'income_amount': summary['income'] ?? 0,
        'expense_amount': summary['expense'] ?? 0,
        'savings_amount': (summary['income'] ?? 0) - (summary['expense'] ?? 0),
        if (_whatEarnedController.text.trim().isNotEmpty) 'what_earned': _whatEarnedController.text.trim(),
        if (_whatSpentController.text.trim().isNotEmpty) 'what_spent': _whatSpentController.text.trim(),
        if (_improveController.text.trim().isNotEmpty) 'how_could_improve': _improveController.text.trim(),
        if (_savingsNoteController.text.trim().isNotEmpty) 'savings_goal_note': _savingsNoteController.text.trim(),
        if (_moodScore != null) 'mood_score': _moodScore,
      }, onConflict: 'profile_id,week_start_date');

      ref.invalidate(weeklyReflectionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refleksi minggu ini tersimpan 🎋')));
        // Clear form
        _whatEarnedController.clear();
        _whatSpentController.clear();
        _improveController.clear();
        _savingsNoteController.clear();
        setState(() => _moodScore = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal simpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(monthlySummaryProvider);
    final reflections = ref.watch(weeklyReflectionsProvider);

    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: KakeiboColors.paper,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('振り返り', style: KakeiboTextStyles.displaySmall.copyWith(fontSize: 18)),
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(child: _ThisWeekSection(weekStart: _weekStart, summary: summary)),
          SliverToBoxAdapter(
            child: _KakeiboQuestions(
              whatEarnedController: _whatEarnedController,
              whatSpentController: _whatSpentController,
              improveController: _improveController,
              savingsNoteController: _savingsNoteController,
            ),
          ),
          SliverToBoxAdapter(
            child: _MoodSection(
              moodScore: _moodScore,
              onMoodChanged: (score) => setState(() => _moodScore = score),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Refleksi'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text('Refleksi Sebelumnya', style: KakeiboTextStyles.labelLarge),
            ),
          ),
          reflections.when(
            data: (list) => list.isEmpty
                ? const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Belum ada refleksi sebelumnya'))))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PastReflectionCard(reflection: list[i]),
                      childCount: list.length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ThisWeekSection extends StatelessWidget {
  final DateTime weekStart;
  final AsyncValue<Map<String, double>> summary;
  const _ThisWeekSection({required this.weekStart, required this.summary});

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', 'id_ID');
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: KakeiboColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${fmt.format(weekStart)} – ${fmt.format(weekEnd)}',
              style: KakeiboTextStyles.labelSmall.copyWith(color: Colors.white54, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Minggu Ini', style: KakeiboTextStyles.displaySmall.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          summary.when(
            data: (data) => Row(
              children: [
                Expanded(child: _SummaryItem(label: 'Pemasukan', value: (data['income'] ?? 0).toRupiah(compact: true), color: const Color(0xFF81C784))),
                Expanded(child: _SummaryItem(label: 'Pengeluaran', value: (data['expense'] ?? 0).toRupiah(compact: true), color: const Color(0xFFEF9A9A))),
                Expanded(child: _SummaryItem(label: 'Tabungan', value: (data['balance'] ?? 0).toRupiah(compact: true), color: const Color(0xFFFFD54F))),
              ],
            ),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: KakeiboTextStyles.labelSmall.copyWith(color: Colors.white38)),
      const SizedBox(height: 2),
      Text(value, style: KakeiboTextStyles.amountMedium(color: color).copyWith(fontSize: 13)),
    ],
  );
}

class _KakeiboQuestions extends StatelessWidget {
  final TextEditingController whatEarnedController, whatSpentController, improveController, savingsNoteController;
  const _KakeiboQuestions({required this.whatEarnedController, required this.whatSpentController, required this.improveController, required this.savingsNoteController});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(children: [
      _QuestionField(number: '01', question: 'Berapa banyak yang saya hasilkan minggu ini?', hint: 'Ceritakan penghasilanmu...', controller: whatEarnedController, color: KakeiboColors.needs),
      const SizedBox(height: 12),
      _QuestionField(number: '02', question: 'Berapa banyak yang saya habiskan?', hint: 'Apa saja yang dibeli minggu ini?', controller: whatSpentController, color: KakeiboColors.wants),
      const SizedBox(height: 12),
      _QuestionField(number: '03', question: 'Bagaimana saya bisa lebih hemat?', hint: 'Apa yang bisa diperbaiki minggu depan?', controller: improveController, color: KakeiboColors.culture),
      const SizedBox(height: 12),
      _QuestionField(number: '04', question: 'Berapa yang ingin saya tabung?', hint: 'Target tabunganmu...', controller: savingsNoteController, color: KakeiboColors.unexpected),
    ]),
  );
}

class _QuestionField extends StatelessWidget {
  final String number, question, hint;
  final TextEditingController controller;
  final Color color;
  const _QuestionField({required this.number, required this.question, required this.hint, required this.controller, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: KakeiboColors.paperWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: KakeiboColors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
          child: Text(number, style: KakeiboTextStyles.labelSmall.copyWith(color: color)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(question, style: KakeiboTextStyles.labelMedium)),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
        style: KakeiboTextStyles.bodyLarge,
      ),
    ]),
  );
}

class _MoodSection extends StatelessWidget {
  final int? moodScore;
  final Function(int) onMoodChanged;
  const _MoodSection({required this.moodScore, required this.onMoodChanged});

  @override
  Widget build(BuildContext context) {
    const moods = ['😔', '😕', '😐', '😊', '😄'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: KakeiboColors.paperWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: KakeiboColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bagaimana perasaanmu minggu ini?', style: KakeiboTextStyles.labelLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            final isSelected = moodScore == score;
            return GestureDetector(
              onTap: () => onMoodChanged(score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: isSelected ? KakeiboColors.ink : KakeiboColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? KakeiboColors.ink : KakeiboColors.divider),
                ),
                child: Center(child: Text(moods[i], style: const TextStyle(fontSize: 24))),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _PastReflectionCard extends StatelessWidget {
  final WeeklyReflectionEntity reflection;
  const _PastReflectionCard({required this.reflection});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM', 'id_ID');
    const moods = ['', '😔', '😕', '😐', '😊', '😄'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KakeiboColors.paperWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: KakeiboColors.divider)),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${fmt.format(reflection.weekStartDate)} – ${fmt.format(reflection.weekEndDate)}', style: KakeiboTextStyles.labelMedium),
          const SizedBox(height: 2),
          Text('Tabungan: ${reflection.savingsAmount.toRupiah(compact: true)}', style: KakeiboTextStyles.bodySmall),
        ]),
        const Spacer(),
        if (reflection.moodScore != null)
          Text(moods[reflection.moodScore!], style: const TextStyle(fontSize: 24)),
      ]),
    );
  }
}
