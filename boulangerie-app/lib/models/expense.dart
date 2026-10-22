import 'json.dart';

enum ExpenseCategory {
  electricity,
  rent,
  transport,
  packaging,
  other;

  /// Électricité et loyer sont facturés au mois (period_month obligatoire).
  bool get isMonthly => this == electricity || this == rent;
}

enum ExpenseStatus { paid, due, overdue }

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.label,
    required this.amount,
    required this.expenseDate,
    required this.periodMonth,
    required this.dueDate,
    required this.paidAt,
    required this.status,
  });

  factory Expense.fromJson(Json json) => Expense(
        id: asInt(json['id']),
        category: ExpenseCategory.values.byName(json['category'] as String),
        label: json['label'] as String,
        amount: asInt(json['amount']),
        expenseDate: asDate(json['expense_date']),
        periodMonth: json['period_month'] == null ? null : asDate(json['period_month']),
        dueDate: asDateOrNull(json['due_date']),
        paidAt: asDateOrNull(json['paid_at']),
        status: ExpenseStatus.values.byName(json['status'] as String),
      );

  final int id;
  final ExpenseCategory category;
  final String label;
  final int amount;
  final DateTime expenseDate;

  /// Premier jour du mois facturé, pour les charges mensuelles.
  final DateTime? periodMonth;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final ExpenseStatus status;
}

class ExpenseList {
  const ExpenseList({required this.expenses, required this.total, required this.unpaidTotal});

  factory ExpenseList.fromJson(Json json) {
    final summary = asJson(json['summary']);
    return ExpenseList(
      expenses: asList(json['data'], Expense.fromJson),
      total: asInt(summary['total']),
      unpaidTotal: asInt(summary['unpaid_total']),
    );
  }

  final List<Expense> expenses;
  final int total;
  final int unpaidTotal;
}
