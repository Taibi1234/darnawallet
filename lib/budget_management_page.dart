import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'transaction_utils.dart';

const Color budgetNavy = Color(0xFF142B3B);
const Color budgetGreen = Color(0xFF35C995);
const Color budgetBackground = Color(0xFFF5F7F9);

const String budgetStorageKey = 'darnawallet_monthly_budgets';

const List<String> budgetCategories = [
  'Food & groceries',
  'Food & drinks',
  'Transport',
  'Shopping',
  'Utilities',
  'Entertainment',
  'Health',
  'Education',
  'Housing',
  'Other',
];

class BudgetManagementPage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const BudgetManagementPage({super.key, required this.transactions});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  List<Map<String, dynamic>> budgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(budgetStorageKey);

      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        budgets = decoded.map((item) {
          return Map<String, dynamic>.from(item as Map);
        }).toList();
      }
    } catch (_) {
      budgets = [];
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(budgetStorageKey, jsonEncode(budgets));
  }

  double _spentForCategory(String category) {
    final now = DateTime.now();
    double total = 0;

    for (final transaction in widget.transactions) {
      final transactionCategory = transaction['category']?.toString() ?? '';

      final amount = transactionAmount(transaction);

      final date = tryParseTransactionDate(transaction['date']);
      final isCurrentMonth =
          date != null && date.year == now.year && date.month == now.month;

      if (transactionCategory == category && amount < 0 && isCurrentMonth) {
        total += amount.abs();
      }
    }

    return total;
  }

  Future<void> _showBudgetDialog({Map<String, dynamic>? existingBudget}) async {
    final isEditing = existingBudget != null;
    final formKey = GlobalKey<FormState>();

    final amountController = TextEditingController(
      text: isEditing
          ? ((existingBudget['limit'] as num?)?.toStringAsFixed(2) ?? '')
          : '',
    );

    String selectedCategory =
        existingBudget?['category']?.toString() ?? budgetCategories.first;

    final availableCategories = budgetCategories.where((category) {
      return category == selectedCategory ||
          !budgets.any((budget) => budget['category']?.toString() == category);
    }).toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit budget' : 'Create monthly budget'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: availableCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly limit',
                        prefixText: 'MAD ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');

                        if (amount == null || !amount.isFinite || amount <= 0) {
                          return 'Enter an amount greater than zero';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Spending is calculated from expenses '
                      'recorded in the current month.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: budgetNavy),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(dialogContext, {
                      'category': selectedCategory,
                      'limit': double.parse(amountController.text.trim()),
                    });
                  },
                  child: Text(isEditing ? 'Save changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    // Preserve the controller until the dialog's closing animation ends.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    amountController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (isEditing) {
        final index = budgets.indexWhere(
          (budget) => budget['category'] == existingBudget['category'],
        );

        if (index != -1) {
          budgets[index] = result;
        }
      } else {
        budgets.add(result);
      }
    });

    await _saveBudgets();
  }

  Future<void> _deleteBudget(Map<String, dynamic> budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('Remove the ${budget['category']} monthly budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      budgets.removeWhere((item) => item['category'] == budget['category']);
    });

    await _saveBudgets();
  }

  String _money(double amount) => 'MAD ${amount.toStringAsFixed(2)}';

  Widget _buildBudgetAlert({
    required bool isOverBudget,
    required double spent,
    required double limit,
    required double left,
  }) {
    final Color alertColor = isOverBudget ? Colors.red : Colors.orange.shade900;

    final String message = isOverBudget
        ? 'Budget exceeded by ${_money(left.abs())}.'
        : 'Budget alert: you have used '
              '${(spent / limit * 100).round()}% of this budget.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverBudget
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isOverBudget
                ? Icons.warning_rounded
                : Icons.notifications_active_outlined,
            color: alertColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: alertColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = budgets.fold<double>(
      0,
      (sum, budget) => sum + ((budget['limit'] as num?)?.toDouble() ?? 0),
    );

    final totalSpent = budgets.fold<double>(
      0,
      (sum, budget) =>
          sum + _spentForCategory(budget['category']?.toString() ?? 'Other'),
    );

    final remaining = totalBudget - totalSpent;
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Scaffold(
      backgroundColor: budgetBackground,
      appBar: AppBar(
        title: const Text(
          'Monthly Budgets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: budgetNavy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetDialog(),
        backgroundColor: budgetGreen,
        foregroundColor: budgetNavy,
        icon: const Icon(Icons.add),
        label: const Text('New budget'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  '${months[now.month - 1]} ${now.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: budgetNavy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total budget',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _money(totalBudget),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: 'Spent',
                              value: _money(totalSpent),
                              color: Colors.orangeAccent,
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: remaining < 0
                                  ? 'Over budget'
                                  : 'Remaining',
                              value: _money(remaining.abs()),
                              color: remaining < 0
                                  ? Colors.redAccent
                                  : budgetGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your categories',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: budgetNavy,
                      ),
                    ),
                    Text(
                      '${budgets.length} budgets',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (budgets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 48,
                          color: budgetGreen,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No budgets yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Create a budget to start tracking '
                          'your monthly spending.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  ...budgets.map((budget) {
                    final category = budget['category']?.toString() ?? 'Other';

                    final limit = (budget['limit'] as num?)?.toDouble() ?? 0;

                    final spent = _spentForCategory(category);
                    final left = limit - spent;

                    final progress = limit > 0
                        ? (spent / limit).clamp(0.0, 1.0)
                        : 0.0;

                    final isOverBudget = limit > 0 && spent > limit;
                    final isNearlyOver = limit > 0 && spent >= limit * 0.8;

                    final Color progressColor = isOverBudget
                        ? Colors.red
                        : isNearlyOver
                        ? Colors.orange
                        : budgetGreen;

                    final percentage = limit > 0
                        ? (spent / limit * 100).round()
                        : 0;

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: budgetGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: budgetNavy,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showBudgetDialog(existingBudget: budget);
                                    } else if (value == 'delete') {
                                      _deleteBudget(budget);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _money(spent),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'of ${_money(limit)}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 9,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isOverBudget
                                        ? 'Over budget by ${_money(left.abs())}'
                                        : '${_money(left)} remaining',
                                    style: TextStyle(
                                      color: isOverBudget
                                          ? Colors.red
                                          : isNearlyOver
                                          ? Colors.orange.shade800
                                          : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    color: progressColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (isNearlyOver) ...[
                              const SizedBox(height: 10),
                              _buildBudgetAlert(
                                isOverBudget: isOverBudget,
                                spent: spent,
                                limit: limit,
                                left: left,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
