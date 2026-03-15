import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String profileId;
  final String accountId;
  final String? categoryId;
  final String type;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final String? categoryName;
  final String? categoryKakeiboType;
  final String? categoryIcon;
  final String? categoryColor;
  final String? accountName;

  const TransactionEntity({
    required this.id,
    required this.profileId,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
    this.categoryName,
    this.categoryKakeiboType,
    this.categoryIcon,
    this.categoryColor,
    this.accountName,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  @override
  List<Object?> get props => [id, profileId, accountId, categoryId, type, amount, note, date];
}

class ProfileEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String currency;
  final double monthlyBudget;
  final DateTime createdAt;

  const ProfileEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.currency,
    required this.monthlyBudget,
    required this.createdAt,
  });

  String get displayName => fullName ?? email.split('@').first;

  @override
  List<Object?> get props => [id, email, fullName, currency, monthlyBudget];
}

class CategoryEntity extends Equatable {
  final String id;
  final String? profileId;
  final String name;
  final String nameEn;
  final String kakeiboType;
  final String icon;
  final String color;
  final bool isSystem;

  const CategoryEntity({
    required this.id,
    this.profileId,
    required this.name,
    required this.nameEn,
    required this.kakeiboType,
    required this.icon,
    required this.color,
    required this.isSystem,
  });

  @override
  List<Object?> get props => [id, name, kakeiboType];
}

class SavingsGoalEntity extends Equatable {
  final String id;
  final String profileId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String icon;
  final String color;
  final bool isCompleted;
  final DateTime createdAt;

  const SavingsGoalEntity({
    required this.id,
    required this.profileId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.createdAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  @override
  List<Object?> get props => [id, name, targetAmount, currentAmount];
}

class WeeklyReflectionEntity extends Equatable {
  final String id;
  final String profileId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final double incomeAmount;
  final double expenseAmount;
  final double savingsAmount;
  final String? whatEarned;
  final String? whatSpent;
  final String? howCouldImprove;
  final String? savingsGoalNote;
  final int? moodScore;
  final DateTime createdAt;

  const WeeklyReflectionEntity({
    required this.id,
    required this.profileId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.savingsAmount,
    this.whatEarned,
    this.whatSpent,
    this.howCouldImprove,
    this.savingsGoalNote,
    this.moodScore,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, weekStartDate];
}

class DashboardSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double savingsAmount;
  final Map<String, double> expenseByKakeiboType;
  final List<TransactionEntity> recentTransactions;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.savingsAmount,
    required this.expenseByKakeiboType,
    required this.recentTransactions,
  });

  double get savingsRate => totalIncome > 0 ? (savingsAmount / totalIncome) * 100 : 0;

  @override
  List<Object?> get props => [totalIncome, totalExpense, balance];
}

class AccountEntity extends Equatable {
  final String id;
  final String profileId;
  final String name;
  final String type;
  final double balance;
  final String color;
  final String icon;
  final bool isDefault;

  const AccountEntity({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, name, balance];
}
