import '../../domain/entities/entities.dart';

// ============================================================
// TRANSACTION MODEL
// ============================================================
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.profileId,
    required super.accountId,
    super.categoryId,
    required super.type,
    required super.amount,
    super.note,
    required super.date,
    required super.createdAt,
    super.categoryName,
    super.categoryKakeiboType,
    super.categoryIcon,
    super.categoryColor,
    super.accountName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final account = json['accounts'] as Map<String, dynamic>?;
    return TransactionModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      categoryName: category?['name'] as String?,
      categoryKakeiboType: category?['kakeibo_type'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      accountName: account?['name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'profile_id': profileId,
    'account_id': accountId,
    if (categoryId != null) 'category_id': categoryId,
    'type': type,
    'amount': amount,
    if (note != null) 'note': note,
    'date': date.toIso8601String().split('T')[0],
  };
}

// ============================================================
// CATEGORY MODEL
// ============================================================
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    super.profileId,
    required super.name,
    required super.nameEn,
    required super.kakeiboType,
    required super.icon,
    required super.color,
    required super.isSystem,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    profileId: json['profile_id'] as String?,
    name: json['name'] as String,
    nameEn: json['name_en'] as String,
    kakeiboType: json['kakeibo_type'] as String,
    icon: json['icon'] as String? ?? 'category',
    color: json['color'] as String? ?? '#888888',
    isSystem: json['is_system'] as bool? ?? false,
  );
}

// ============================================================
// PROFILE MODEL
// ============================================================
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    required super.currency,
    required super.monthlyBudget,
    required super.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    currency: json['currency'] as String? ?? 'IDR',
    monthlyBudget: (json['monthly_budget'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toUpdateJson() => {
    if (fullName != null) 'full_name': fullName,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'currency': currency,
    'monthly_budget': monthlyBudget,
  };
}

// ============================================================
// ACCOUNT MODEL
// ============================================================
class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.profileId,
    required super.name,
    required super.type,
    required super.balance,
    required super.color,
    required super.icon,
    required super.isDefault,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    balance: (json['balance'] as num).toDouble(),
    color: json['color'] as String? ?? '#4A90E2',
    icon: json['icon'] as String? ?? 'wallet',
    isDefault: json['is_default'] as bool? ?? false,
  );

  Map<String, dynamic> toInsertJson() => {
    'profile_id': profileId,
    'name': name,
    'type': type,
    'balance': balance,
    'color': color,
    'icon': icon,
    'is_default': isDefault,
  };
}

// ============================================================
// SAVINGS GOAL MODEL
// ============================================================
class SavingsGoalModel extends SavingsGoalEntity {
  const SavingsGoalModel({
    required super.id,
    required super.profileId,
    required super.name,
    required super.targetAmount,
    required super.currentAmount,
    super.targetDate,
    required super.icon,
    required super.color,
    required super.isCompleted,
    required super.createdAt,
  });

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) => SavingsGoalModel(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    name: json['name'] as String,
    targetAmount: (json['target_amount'] as num).toDouble(),
    currentAmount: (json['current_amount'] as num).toDouble(),
    targetDate: json['target_date'] != null
        ? DateTime.parse(json['target_date'] as String) : null,
    icon: json['icon'] as String? ?? 'savings',
    color: json['color'] as String? ?? '#2A9D8F',
    isCompleted: json['is_completed'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'profile_id': profileId,
    'name': name,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    if (targetDate != null) 'target_date': targetDate!.toIso8601String().split('T')[0],
    'icon': icon,
    'color': color,
    'is_completed': isCompleted,
  };
}

// ============================================================
// WEEKLY REFLECTION MODEL
// ============================================================
class WeeklyReflectionModel extends WeeklyReflectionEntity {
  const WeeklyReflectionModel({
    required super.id,
    required super.profileId,
    required super.weekStartDate,
    required super.weekEndDate,
    required super.incomeAmount,
    required super.expenseAmount,
    required super.savingsAmount,
    super.whatEarned,
    super.whatSpent,
    super.howCouldImprove,
    super.savingsGoalNote,
    super.moodScore,
    required super.createdAt,
  });

  factory WeeklyReflectionModel.fromJson(Map<String, dynamic> json) =>
      WeeklyReflectionModel(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        weekStartDate: DateTime.parse(json['week_start_date'] as String),
        weekEndDate: DateTime.parse(json['week_end_date'] as String),
        incomeAmount: (json['income_amount'] as num?)?.toDouble() ?? 0,
        expenseAmount: (json['expense_amount'] as num?)?.toDouble() ?? 0,
        savingsAmount: (json['savings_amount'] as num?)?.toDouble() ?? 0,
        whatEarned: json['what_earned'] as String?,
        whatSpent: json['what_spent'] as String?,
        howCouldImprove: json['how_could_improve'] as String?,
        savingsGoalNote: json['savings_goal_note'] as String?,
        moodScore: json['mood_score'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toUpsertJson() => {
    'profile_id': profileId,
    'week_start_date': weekStartDate.toIso8601String().split('T')[0],
    'week_end_date': weekEndDate.toIso8601String().split('T')[0],
    'income_amount': incomeAmount,
    'expense_amount': expenseAmount,
    'savings_amount': savingsAmount,
    if (whatEarned != null) 'what_earned': whatEarned,
    if (whatSpent != null) 'what_spent': whatSpent,
    if (howCouldImprove != null) 'how_could_improve': howCouldImprove,
    if (savingsGoalNote != null) 'savings_goal_note': savingsGoalNote,
    if (moodScore != null) 'mood_score': moodScore,
  };
}
