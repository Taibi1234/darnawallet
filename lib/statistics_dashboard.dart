import 'package:flutter/material.dart';

import 'transaction_utils.dart';

const Color statsNavy = Color(0xFF142B3B);
const Color statsGreen = Color(0xFF35C995);
const Color statsBackground = Color(0xFFF5F7F9);
const Color statsRed = Color(0xFFE78383);

class StatisticsDashboard extends StatelessWidget {
  const StatisticsDashboard({super.key, required this.transactions});

  final List<Map<String, dynamic>> transactions;

  double get totalIncome => totalIncomeOf(transactions);

  double get totalExpenses => totalExpensesOf(transactions);

  Map<String, double> get expensesByCategory {
    final result = <String, double>{};

    for (final transaction in transactions) {
      final amount = transactionAmount(transaction);

      if (amount >= 0) continue;

      final category = transaction['category']?.toString() ?? 'Other';

      result[category] = (result[category] ?? 0) + amount.abs();
    }

    return result;
  }

  // Undatable legacy records count toward the current month so they stay
  // visible in the charts; the UI copy below explains this to the user.
  DateTime _transactionDate(Map<String, dynamic> transaction) {
    final now = DateTime.now();
    return tryParseTransactionDate(transaction['date'], now: now) ??
        DateTime(now.year, now.month, now.day);
  }

  List<MonthlyTotal> get monthlyTotals {
    final now = DateTime.now();

    return List.generate(6, (index) {
      final offset = 5 - index;
      final monthDate = DateTime(now.year, now.month - offset);

      double income = 0;
      double expenses = 0;

      for (final transaction in transactions) {
        final date = _transactionDate(transaction);

        if (date.year != monthDate.year || date.month != monthDate.month) {
          continue;
        }

        final amount = transactionAmount(transaction);

        if (amount > 0) {
          income += amount;
        } else {
          expenses += amount.abs();
        }
      }

      return MonthlyTotal(
        label: _monthName(monthDate.month),
        income: income,
        expenses: expenses,
      );
    });
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final categories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final expenseTransactionCount = transactions
        .where((t) => transactionAmount(t) < 0)
        .length;

    final months = monthlyTotals;
    final maxMonthlyValue = months.fold<double>(0, (maximum, month) {
      final largest = month.income > month.expenses
          ? month.income
          : month.expenses;
      return largest > maximum ? largest : maximum;
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
      children: [
        const Text(
          'Financial insights',
          style: TextStyle(
            color: statsNavy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Understand where your money goes.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 22),

        // Income and expense totals
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total income',
                amount: formatMoney(totalIncome),
                color: statsGreen,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Total expenses',
                amount: formatMoney(totalExpenses),
                color: statsRed,
                icon: Icons.trending_down_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Income vs expenses
        _SectionCard(
          title: 'Income vs. expenses',
          subtitle: 'All recorded transactions',
          child: Column(
            children: [
              _ComparisonBar(
                label: 'Income',
                amount: totalIncome,
                maximum: totalIncome > totalExpenses
                    ? totalIncome
                    : totalExpenses,
                color: statsGreen,
                money: formatMoney,
              ),
              const SizedBox(height: 20),
              _ComparisonBar(
                label: 'Expenses',
                amount: totalExpenses,
                maximum: totalIncome > totalExpenses
                    ? totalIncome
                    : totalExpenses,
                color: statsRed,
                money: formatMoney,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statsBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: statsNavy,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Net cash flow',
                        style: TextStyle(
                          color: statsNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${totalIncome >= totalExpenses ? '+' : '-'}${formatMoney((totalIncome - totalExpenses).abs())} MAD',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: totalIncome >= totalExpenses
                              ? const Color(0xFF168866)
                              : statsRed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Spending categories
        _SectionCard(
          title: 'Spending by category',
          subtitle: 'Where your expenses are going',
          child: categories.isEmpty
              ? const _EmptyMessage(
                  message: 'Add an expense to see your categories.',
                )
              : Column(
                  children: [
                    ...categories.map((entry) {
                      final percentage = totalExpenses == 0
                          ? 0.0
                          : entry.value / totalExpenses;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: statsNavy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${formatMoney(entry.value)} MAD',
                                  style: const TextStyle(
                                    color: statsNavy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: percentage.clamp(0.0, 1.0),
                                minHeight: 9,
                                backgroundColor: statsBackground,
                                color: _categoryColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),

        const SizedBox(height: 20),

        // Monthly trends
        _SectionCard(
          title: 'Monthly trends',
          subtitle: 'Income and expenses over six months',
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: statsGreen, label: 'Income'),
                  SizedBox(width: 20),
                  _LegendDot(color: statsRed, label: 'Expenses'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: months.map((month) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _MonthBar(
                                      value: month.income,
                                      maximum: maxMonthlyValue,
                                      color: statsGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: _MonthBar(
                                      value: month.expenses,
                                      maximum: maxMonthlyValue,
                                      color: statsRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              month.label,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Older demo transactions without calendar dates are '
                'assigned to the current month.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _SectionCard(
          title: 'Transaction summary',
          subtitle: 'Your recorded activity',
          child: Column(
            children: [
              _InfoRow(
                label: 'Total transactions',
                value: '${transactions.length}',
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Income transactions',
                value:
                    '${transactions.where((t) => transactionAmount(t) > 0).length}',
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Expense transactions',
                value:
                    '${transactions.where((t) => transactionAmount(t) < 0).length}',
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Average expense',
                value: expenseTransactionCount == 0
                    ? '0.00 MAD'
                    : '${formatMoney(totalExpenses / expenseTransactionCount)} MAD',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Center(
          child: Text(
            'DarnaWallet · Demo financial data',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
      case 'food & drinks':
        return const Color(0xFF35C995);
      case 'transport':
        return const Color(0xFF6395E8);
      case 'shopping':
        return const Color(0xFFB18AE0);
      case 'utilities':
        return const Color(0xFFE9B45B);
      default:
        return const Color(0xFF5C8497);
    }
  }
}

class MonthlyTotal {
  const MonthlyTotal({
    required this.label,
    required this.income,
    required this.expenses,
  });

  final String label;
  final double income;
  final double expenses;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: const TextStyle(
                color: statsNavy,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MAD',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: statsNavy,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.amount,
    required this.maximum,
    required this.color,
    required this.money,
  });

  final String label;
  final double amount;
  final double maximum;
  final Color color;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final progress = maximum <= 0 ? 0.0 : (amount / maximum).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: statsNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${money(amount)} MAD',
              style: const TextStyle(
                color: statsNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: statsBackground,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.value,
    required this.maximum,
    required this.color,
  });

  final double value;
  final double maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maximum <= 0 ? 0.0 : (value / maximum).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = constraints.maxHeight * ratio;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: value == 0
                ? 0
                : barHeight.clamp(3.0, constraints.maxHeight),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: statsNavy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
