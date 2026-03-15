import 'package:dartz/dartz.dart';
import '../../domain/entities/entities.dart';
import '../datasources/supabase_datasource.dart';
import '../models/models.dart';

// ============================================================
// FAILURE TYPE
// ============================================================
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// ============================================================
// TRANSACTION REPOSITORY
// ============================================================
class TransactionRepository {
  final TransactionRemoteDataSource _dataSource;

  TransactionRepository(this._dataSource);

  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      final result = await _dataSource.getTransactions(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, TransactionEntity>> addTransaction({
    required String accountId,
    required String profileId,
    required String type,
    required double amount,
    String? categoryId,
    String? note,
    DateTime? date,
  }) async {
    try {
      final model = TransactionModel(
        id: '', // Will be set by DB
        profileId: profileId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        note: note,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
      );
      final result = await _dataSource.addTransaction(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _dataSource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, double>>> getMonthlySummary(
      int year, int month) async {
    try {
      final result = await _dataSource.getMonthlySummary(year, month);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, double>>> getKakeiboBreakdown(
      int year, int month) async {
    try {
      final result = await _dataSource.getKakeiboBreakdown(year, month);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ============================================================
// CATEGORY REPOSITORY
// ============================================================
class CategoryRepository {
  final CategoryRemoteDataSource _dataSource;

  CategoryRepository(this._dataSource);

  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final result = await _dataSource.getCategories();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ============================================================
// ACCOUNT REPOSITORY
// ============================================================
class AccountRepository {
  final AccountRemoteDataSource _dataSource;

  AccountRepository(this._dataSource);

  Future<Either<Failure, List<AccountEntity>>> getAccounts() async {
    try {
      final result = await _dataSource.getAccounts();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, AccountEntity>> createAccount({
    required String profileId,
    required String name,
    required String type,
    required double initialBalance,
    String color = '#4A90E2',
    String icon = 'wallet',
    bool isDefault = false,
  }) async {
    try {
      final model = AccountModel(
        id: '',
        profileId: profileId,
        name: name,
        type: type,
        balance: initialBalance,
        color: color,
        icon: icon,
        isDefault: isDefault,
      );
      final result = await _dataSource.createAccount(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ============================================================
// SAVINGS GOAL REPOSITORY
// ============================================================
class SavingsGoalRepository {
  final SavingsGoalRemoteDataSource _dataSource;

  SavingsGoalRepository(this._dataSource);

  Future<Either<Failure, List<SavingsGoalEntity>>> getSavingsGoals() async {
    try {
      final result = await _dataSource.getSavingsGoals();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SavingsGoalEntity>> createSavingsGoal({
    required String profileId,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    String icon = 'savings',
    String color = '#2A9D8F',
  }) async {
    try {
      final model = SavingsGoalModel(
        id: '',
        profileId: profileId,
        name: name,
        targetAmount: targetAmount,
        currentAmount: 0,
        targetDate: targetDate,
        icon: icon,
        color: color,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      final result = await _dataSource.createSavingsGoal(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SavingsGoalEntity>> addToSavingsGoal(
      String id, double amount) async {
    try {
      final goals = await _dataSource.getSavingsGoals();
      final goal = goals.firstWhere((g) => g.id == id);
      final newAmount = goal.currentAmount + amount;
      final result = await _dataSource.updateSavingsGoal(id, {
        'current_amount': newAmount,
        'is_completed': newAmount >= goal.targetAmount,
      });
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ============================================================
// WEEKLY REFLECTION REPOSITORY
// ============================================================
class WeeklyReflectionRepository {
  final WeeklyReflectionRemoteDataSource _dataSource;

  WeeklyReflectionRepository(this._dataSource);

  Future<Either<Failure, List<WeeklyReflectionEntity>>> getReflections() async {
    try {
      final result = await _dataSource.getReflections();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, WeeklyReflectionEntity?>> getCurrentWeekReflection() async {
    try {
      final now = DateTime.now();
      final weekday = now.weekday;
      final weekStart = now.subtract(Duration(days: weekday - 1));
      final result = await _dataSource.getReflectionForWeek(
        DateTime(weekStart.year, weekStart.month, weekStart.day),
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, WeeklyReflectionEntity>> saveReflection({
    required String profileId,
    required DateTime weekStart,
    required double incomeAmount,
    required double expenseAmount,
    required double savingsAmount,
    String? whatEarned,
    String? whatSpent,
    String? howCouldImprove,
    String? savingsGoalNote,
    int? moodScore,
  }) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final model = WeeklyReflectionModel(
        id: '',
        profileId: profileId,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        incomeAmount: incomeAmount,
        expenseAmount: expenseAmount,
        savingsAmount: savingsAmount,
        whatEarned: whatEarned,
        whatSpent: whatSpent,
        howCouldImprove: howCouldImprove,
        savingsGoalNote: savingsGoalNote,
        moodScore: moodScore,
        createdAt: DateTime.now(),
      );
      final result = await _dataSource.upsertReflection(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ============================================================
// PROFILE REPOSITORY
// ============================================================
class ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  ProfileRepository(this._dataSource);

  Future<Either<Failure, ProfileEntity?>> getProfile() async {
    try {
      final result = await _dataSource.getProfile();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? currency,
    double? monthlyBudget,
  }) async {
    try {
      final result = await _dataSource.updateProfile({
        if (fullName != null) 'full_name': fullName,
        if (currency != null) 'currency': currency,
        if (monthlyBudget != null) 'monthly_budget': monthlyBudget,
      });
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
