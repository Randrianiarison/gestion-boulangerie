import 'json.dart';

enum EmployeeRole { preparation, sales, delivery, other }

/// Calcul du SalaryCalculator côté API : solde dû = acquis - payé (négatif = avance).
class SalarySummary {
  const SalarySummary({
    required this.accrued,
    required this.paid,
    required this.balance,
    required this.currentRate,
    required this.unpaidMonths,
  });

  factory SalarySummary.fromJson(Json json) => SalarySummary(
        accrued: asInt(json['accrued']),
        paid: asInt(json['paid']),
        balance: asInt(json['balance']),
        currentRate: asInt(json['current_rate']),
        unpaidMonths: json['unpaid_months'] == null ? null : asDouble(json['unpaid_months']),
      );

  final int accrued;
  final int paid;
  final int balance;
  final int currentRate;
  final double? unpaidMonths;
}

class SalaryRate {
  const SalaryRate({required this.id, required this.monthlyAmount, required this.effectiveFrom});

  factory SalaryRate.fromJson(Json json) => SalaryRate(
        id: asInt(json['id']),
        monthlyAmount: asInt(json['monthly_amount']),
        effectiveFrom: asDate(json['effective_from']),
      );

  final int id;
  final int monthlyAmount;
  final DateTime effectiveFrom;
}

class SalaryPayment {
  const SalaryPayment({required this.id, required this.amount, required this.paidOn, required this.note});

  factory SalaryPayment.fromJson(Json json) => SalaryPayment(
        id: asInt(json['id']),
        amount: asInt(json['amount']),
        paidOn: asDate(json['paid_on']),
        note: json['note'] as String?,
      );

  final int id;
  final int amount;
  final DateTime paidOn;
  final String? note;
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.hiredOn,
    required this.leftOn,
    required this.active,
    required this.salary,
    this.rates = const [],
    this.payments = const [],
  });

  factory Employee.fromJson(Json json) => Employee(
        id: asInt(json['id']),
        name: json['name'] as String,
        phone: json['phone'] as String?,
        role: EmployeeRole.values.byName(json['role'] as String),
        hiredOn: asDate(json['hired_on']),
        leftOn: asDateOrNull(json['left_on']),
        active: json['active'] as bool,
        salary: json['salary'] == null ? null : SalarySummary.fromJson(asJson(json['salary'])),
        rates: asList(json['salary_rates'], SalaryRate.fromJson),
        payments: asList(json['payments'], SalaryPayment.fromJson),
      );

  final int id;
  final String name;
  final String? phone;
  final EmployeeRole role;
  final DateTime hiredOn;
  final DateTime? leftOn;
  final bool active;
  final SalarySummary? salary;
  final List<SalaryRate> rates;
  final List<SalaryPayment> payments;
}

class EmployeeList {
  const EmployeeList({required this.employees, required this.totalDue});

  factory EmployeeList.fromJson(Json json) => EmployeeList(
        employees: asList(json['data'], Employee.fromJson),
        totalDue: asInt(json['total_due']),
      );

  final List<Employee> employees;
  final int totalDue;
}
