import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../transactions/data/datasources/supabase_datasource.dart';
import '../../../transactions/data/repositories/repositories.dart';
import '../../../transactions/domain/entities/entities.dart';

// ============================================================
// SUPABASE CLIENT PROVIDER
// ============================================================
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ============================================================
// AUTH PROVIDERS
// ============================================================
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ============================================================
// DATASOURCE PROVIDERS
// ============================================================
final transactionDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TransactionRemoteDataSource(client);
});

final categoryDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CategoryRemoteDataSource(client);
});

final accountDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AccountRemoteDataSource(client);
});

final profileDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRemoteDataSource(client);
});

final savingsGoalDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SavingsGoalRemoteDataSource(client);
});

final weeklyReflectionDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WeeklyReflectionRemoteDataSource(client);
});

// ============================================================
// REPOSITORY PROVIDERS
// ============================================================
final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepository(ref.watch(transactionDataSourceProvider));
});

final categoryRepositoryProvider = Provider((ref) {
  return CategoryRepository(ref.watch(categoryDataSourceProvider));
});

final accountRepositoryProvider = Provider((ref) {
  return AccountRepository(ref.watch(accountDataSourceProvider));
});

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(ref.watch(profileDataSourceProvider));
});

final savingsGoalRepositoryProvider = Provider((ref) {
  return SavingsGoalRepository(ref.watch(savingsGoalDataSourceProvider));
});

final weeklyReflectionRepositoryProvider = Provider((ref) {
  return WeeklyReflectionRepository(ref.watch(weeklyReflectionDataSourceProvider));
});

// ============================================================
// DATA PROVIDERS (Business Logic)
// ============================================================

// Selected month for filtering
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// Profile data
final profileProvider = FutureProvider<ProfileEntity?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.getProfile();
  return result.fold((l) => null, (r) => r);
});

// Accounts
final accountsProvider = FutureProvider<List<AccountEntity>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  final result = await repo.getAccounts();
  return result.fold((l) => [], (r) => r);
});

// Default account
final defaultAccountProvider = Provider<AsyncValue<AccountEntity?>>((ref) {
  final accounts = ref.watch(accountsProvider);
  return accounts.whenData((list) {
    if (list.isEmpty) return null;
    return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
  });
});

// Categories
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getCategories();
  return result.fold((l) => [], (r) => r);
});

// Monthly transactions
final monthlyTransactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  final result = await repo.getTransactions(startDate: start, endDate: end);
  return result.fold((l) => [], (r) => r);
});

// Monthly summary
final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final result = await repo.getMonthlySummary(month.year, month.month);
  return result.fold((l) => {'income': 0, 'expense': 0, 'balance': 0}, (r) => r);
});

// Kakeibo breakdown
final kakeiboBreakdownProvider = FutureProvider<Map<String, double>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final result = await repo.getKakeiboBreakdown(month.year, month.month);
  return result.fold(
    (l) => {'needs': 0, 'wants': 0, 'culture': 0, 'unexpected': 0},
    (r) => r,
  );
});

// Savings goals
final savingsGoalsProvider = FutureProvider<List<SavingsGoalEntity>>((ref) async {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  final result = await repo.getSavingsGoals();
  return result.fold((l) => [], (r) => r);
});

// Weekly reflections
final weeklyReflectionsProvider = FutureProvider<List<WeeklyReflectionEntity>>((ref) async {
  final repo = ref.watch(weeklyReflectionRepositoryProvider);
  final result = await repo.getReflections();
  return result.fold((l) => [], (r) => r);
});

// Current week reflection
final currentWeekReflectionProvider = FutureProvider<WeeklyReflectionEntity?>((ref) async {
  final repo = ref.watch(weeklyReflectionRepositoryProvider);
  final result = await repo.getCurrentWeekReflection();
  return result.fold((l) => null, (r) => r);
});

// ============================================================
// ADD TRANSACTION STATE
// ============================================================
class AddTransactionState {
  final bool isLoading;
  final String? error;
  final bool success;

  const AddTransactionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AddTransactionState copyWith({bool? isLoading, String? error, bool? success}) =>
      AddTransactionState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        success: success ?? this.success,
      );
}

class AddTransactionNotifier extends StateNotifier<AddTransactionState> {
  final TransactionRepository _repo;
  final Ref _ref;

  AddTransactionNotifier(this._repo, this._ref) : super(const AddTransactionState());

  Future<void> addTransaction({
    required String accountId,
    required String profileId,
    required String type,
    required double amount,
    String? categoryId,
    String? note,
    DateTime? date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.addTransaction(
      accountId: accountId,
      profileId: profileId,
      type: type,
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: date,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (transaction) {
        // Invalidate relevant providers to refresh data
        _ref.invalidate(monthlyTransactionsProvider);
        _ref.invalidate(monthlySummaryProvider);
        _ref.invalidate(kakeiboBreakdownProvider);
        _ref.invalidate(accountsProvider);
        state = state.copyWith(isLoading: false, success: true);
      },
    );
  }

  void reset() {
    state = const AddTransactionState();
  }
}

final addTransactionProvider =
    StateNotifierProvider<AddTransactionNotifier, AddTransactionState>((ref) {
  return AddTransactionNotifier(
    ref.watch(transactionRepositoryProvider),
    ref,
  );
});
