import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../domain/entities/entities.dart';

// ============================================================
// TRANSACTION DATASOURCE
// ============================================================
class TransactionRemoteDataSource {
  final SupabaseClient _client;

  TransactionRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Fetch transactions with joined category and account data
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? kakeiboType,
    int limit = 50,
    int offset = 0,
  }) async {
    var queryBuilder = _client
        .from('transactions')
        .select('''
          *,
          categories (name, kakeibo_type, icon, color),
          accounts (name)
        ''')
        .eq('profile_id', _userId);

    if (startDate != null) {
      queryBuilder = queryBuilder.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      queryBuilder = queryBuilder.lte('date', endDate.toIso8601String().split('T')[0]);
    }
    if (type != null) {
      queryBuilder = queryBuilder.eq('type', type);
    }

    final response = await queryBuilder
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  /// Add a new transaction
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    final response = await _client
        .from('transactions')
        .insert(transaction.toInsertJson())
        .select('''
          *,
          categories (name, kakeibo_type, icon, color),
          accounts (name)
        ''')
        .single();
    return TransactionModel.fromJson(response);
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id).eq('profile_id', _userId);
  }

  /// Update a transaction
  Future<TransactionModel> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('transactions')
        .update(data)
        .eq('id', id)
        .eq('profile_id', _userId)
        .select('''
          *,
          categories (name, kakeibo_type, icon, color),
          accounts (name)
        ''')
        .single();
    return TransactionModel.fromJson(response);
  }

  /// Get monthly summary (income vs expense)
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('type, amount')
        .eq('profile_id', _userId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    double income = 0, expense = 0;
    for (final row in response as List) {
      if (row['type'] == 'income') {
        income += (row['amount'] as num).toDouble();
      } else {
        expense += (row['amount'] as num).toDouble();
      }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  /// Get expense breakdown by Kakeibo type for a month
  Future<Map<String, double>> getKakeiboBreakdown(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('amount, categories(kakeibo_type)')
        .eq('profile_id', _userId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    final Map<String, double> breakdown = {
      'needs': 0,
      'wants': 0,
      'culture': 0,
      'unexpected': 0,
    };

    for (final row in response as List) {
      final category = row['categories'] as Map<String, dynamic>?;
      final type = category?['kakeibo_type'] as String? ?? 'unexpected';
      breakdown[type] = (breakdown[type] ?? 0) + (row['amount'] as num).toDouble();
    }

    return breakdown;
  }
}

// ============================================================
// CATEGORY DATASOURCE
// ============================================================
class CategoryRemoteDataSource {
  final SupabaseClient _client;

  CategoryRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .or('is_system.eq.true,profile_id.eq.$_userId')
        .order('kakeibo_type')
        .order('name');

    return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(String kakeiboType) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('kakeibo_type', kakeiboType)
        .or('is_system.eq.true,profile_id.eq.$_userId');

    return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
  }
}

// ============================================================
// ACCOUNT DATASOURCE
// ============================================================
class AccountRemoteDataSource {
  final SupabaseClient _client;

  AccountRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<AccountModel>> getAccounts() async {
    final response = await _client
        .from('accounts')
        .select()
        .eq('profile_id', _userId)
        .order('is_default', ascending: false)
        .order('name');

    return (response as List).map((e) => AccountModel.fromJson(e)).toList();
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    final response = await _client
        .from('accounts')
        .insert(account.toInsertJson())
        .select()
        .single();
    return AccountModel.fromJson(response);
  }

  Future<AccountModel> updateAccount(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('accounts')
        .update(data)
        .eq('id', id)
        .eq('profile_id', _userId)
        .select()
        .single();
    return AccountModel.fromJson(response);
  }
}

// ============================================================
// PROFILE DATASOURCE
// ============================================================
class ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<ProfileModel?> getProfile() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .single();
      return ProfileModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', _userId)
        .select()
        .single();
    return ProfileModel.fromJson(response);
  }
}

// ============================================================
// SAVINGS GOAL DATASOURCE
// ============================================================
class SavingsGoalRemoteDataSource {
  final SupabaseClient _client;

  SavingsGoalRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    final response = await _client
        .from('savings_goals')
        .select()
        .eq('profile_id', _userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => SavingsGoalModel.fromJson(e)).toList();
  }

  Future<SavingsGoalModel> createSavingsGoal(SavingsGoalModel goal) async {
    final response = await _client
        .from('savings_goals')
        .insert(goal.toInsertJson())
        .select()
        .single();
    return SavingsGoalModel.fromJson(response);
  }

  Future<SavingsGoalModel> updateSavingsGoal(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('savings_goals')
        .update(data)
        .eq('id', id)
        .eq('profile_id', _userId)
        .select()
        .single();
    return SavingsGoalModel.fromJson(response);
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _client.from('savings_goals').delete().eq('id', id).eq('profile_id', _userId);
  }
}

// ============================================================
// WEEKLY REFLECTION DATASOURCE
// ============================================================
class WeeklyReflectionRemoteDataSource {
  final SupabaseClient _client;

  WeeklyReflectionRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<WeeklyReflectionModel>> getReflections({int limit = 12}) async {
    final response = await _client
        .from('weekly_reflections')
        .select()
        .eq('profile_id', _userId)
        .order('week_start_date', ascending: false)
        .limit(limit);

    return (response as List).map((e) => WeeklyReflectionModel.fromJson(e)).toList();
  }

  Future<WeeklyReflectionModel?> getReflectionForWeek(DateTime weekStart) async {
    try {
      final response = await _client
          .from('weekly_reflections')
          .select()
          .eq('profile_id', _userId)
          .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
          .single();
      return WeeklyReflectionModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<WeeklyReflectionModel> upsertReflection(WeeklyReflectionModel reflection) async {
    final response = await _client
        .from('weekly_reflections')
        .upsert(
          reflection.toUpsertJson(),
          onConflict: 'profile_id,week_start_date',
        )
        .select()
        .single();
    return WeeklyReflectionModel.fromJson(response);
  }
}
