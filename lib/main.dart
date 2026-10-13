import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'statistics_dashboard.dart';
import 'transaction.dart';
import 'transaction_management_page.dart';
import 'transaction_utils.dart';
import 'budget_management_page.dart';
import 'profile_page.dart';
import 'database/migration.dart';
import 'recurring_processor.dart';


void main() {
  // SQLite migration runs idempotently on startup (database/migration.dart).
  // Legacy SharedPreferences data is preserved until verified.
  DataMigration.runIfNeeded().then(
    (_) => runApp(const DarnaWalletApp()),
    onError: (e) => runApp(const DarnaWalletApp()),
  );
}

const double openingBalance = 6426.50;
const String appVersion = '1.1.0';
const String storageKey = 'darnawallet_transactions';

class DarnaWalletApp extends StatelessWidget {
  const DarnaWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarnaWallet',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WalletHomePage(),
    );
  }
}

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  int selectedIndex = 0;
  bool isLoading = true;

  List<WalletTransaction> transactions = [];

  final List<WalletTransaction> sampleTransactions = const [
    WalletTransaction(
      id: 'demo-1',
      title: 'Grocery shopping',
      category: 'Food & groceries',
      amount: -245.50,
      date: 'Today, 10:42 AM',
    ),
    WalletTransaction(
      id: 'demo-2',
      title: 'Monthly salary',
      category: 'Salary',
      amount: 6500.00,
      date: 'Today, 08:15 AM',
    ),
    WalletTransaction(
      id: 'demo-3',
      title: 'Coffee shop',
      category: 'Food & drinks',
      amount: -32.00,
      date: 'Yesterday, 04:30 PM',
    ),
    WalletTransaction(
      id: 'demo-4',
      title: 'Internet bill',
      category: 'Utilities',
      amount: -199.00,
      date: 'Yesterday, 11:20 AM',
    ),
  ];

  double get totalIncome => totalIncomeOf(transactions);

  double get totalExpenses => totalExpensesOf(transactions);

  double get balance => openingBalance + totalIncome - totalExpenses;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      // First, process any recurring transactions that need to be generated
      await processRecurringTransactions();

      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(storageKey);

      List<WalletTransaction> loadedTransactions;

      if (savedData == null) {
        loadedTransactions = List<WalletTransaction>.from(sampleTransactions);

        await _saveTransactions();
      } else {
        final decoded = jsonDecode(savedData) as List<dynamic>;

        loadedTransactions = decoded.map((item) {
          return WalletTransaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      if (!mounted) return;

      setState(() {
        transactions = loadedTransactions;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        transactions = List<WalletTransaction>.from(sampleTransactions);
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load saved transactions. Showing demo data.',
          ),
        ),
      );
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      transactions.map((transaction) => transaction.toJson()).toList(),
    );
    await prefs.setString(storageKey, encoded);
  }

  IconData _iconFor(String category) {
    final value = category.toLowerCase();

    if (value.contains('salary') || value.contains('income')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (value.contains('food') || value.contains('grocery')) {
      return Icons.shopping_basket_outlined;
    }
    if (value.contains('transport')) {
      return Icons.directions_bus_outlined;
    }
    if (value.contains('bill') || value.contains('utilities')) {
      return Icons.wifi_outlined;
    }
    if (value.contains('shopping')) {
      return Icons.shopping_bag_outlined;
    }

    return Icons.receipt_long_outlined;
  }

  Future<void> _addTransaction({bool initialIncome = false}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        String title = '';
        String amountText = '';
        String category = initialIncome ? 'Salary' : 'Food & groceries';
        bool isIncome = initialIncome;

        return StatefulBuilder(
          builder: (context, refreshDialog) {
            final categories = isIncome
                ? ['Salary', 'Business', 'Gift', 'Other income']
                : [
                    'Food & groceries',
                    'Food & drinks',
                    'Transport',
                    'Shopping',
                    'Utilities',
                    'Other expense',
                  ];

            return AlertDialog(
              title: Text(isIncome ? 'Add income' : 'Add expense'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_upward),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_downward),
                          ),
                        ],
                        selected: {isIncome},
                        onSelectionChanged: (selection) {
                          refreshDialog(() {
                            isIncome = selection.first;
                            category = isIncome ? 'Salary' : 'Food & groceries';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Transaction title',
                          hintText: 'e.g. Monthly salary',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a title';
                          }
                          return null;
                        },
                        onSaved: (value) => title = value!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Amount (MAD)',
                          hintText: 'e.g. 250.00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );

                          if (amount == null ||
                              !amount.isFinite ||
                              amount <= 0) {
                            return 'Enter a valid amount above zero';
                          }

                          return null;
                        },
                        onSaved: (value) => amountText = value!.trim(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            refreshDialog(() => category = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    formKey.currentState!.save();

                    final amount = double.parse(
                      amountText.replaceAll(',', '.'),
                    );

                    Navigator.pop(dialogContext, {
                      'title': title,
                      'category': category,
                      'amount': isIncome ? amount : -amount,
                      'date': DateTime.now().toIso8601String(),
                    });
                  },
                  child: const Text('Save transaction'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final newTransaction = WalletTransaction(
      id: WalletTransaction.generateId(),
      title: result['title'] as String,
      category: result['category'] as String,
      amount: result['amount'] as double,
      date: result['date'] as String,
    );

    setState(() {
      transactions.insert(0, newTransaction);
    });

    try {
      await _saveTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added, but saving failed.')),
      );
    }
  }

  Future<void> _editTransaction(WalletTransaction transaction) async {
    final formKey = GlobalKey<FormState>();

    String title = transaction.title;
    String amountText = transaction.amount.abs().toStringAsFixed(2);
    String category = transaction.category;
    bool isIncome = transaction.isIncome;

    final incomeCategories = ['Salary', 'Business', 'Gift', 'Other income'];

    final expenseCategories = [
      'Food & groceries',
      'Food & drinks',
      'Transport',
      'Shopping',
      'Utilities',
      'Other expense',
    ];

    final allCategories = <String>{
      ...incomeCategories,
      ...expenseCategories,
      category,
    };

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) {
          final categories = allCategories.where((item) {
            final isIncomeCategory = incomeCategories.contains(item);
            return isIncome ? isIncomeCategory : !isIncomeCategory;
          }).toList();

          if (!categories.contains(category)) {
            category = categories.first;
          }

          return AlertDialog(
            title: const Text('Edit transaction'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {isIncome},
                      onSelectionChanged: (selection) {
                        refreshDialog(() {
                          isIncome = selection.first;
                          category = isIncome ? 'Salary' : 'Food & groceries';
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: title,
                      decoration: const InputDecoration(
                        labelText: 'Transaction title',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a title';
                        }
                        return null;
                      },
                      onSaved: (value) => title = value!.trim(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: amountText,
                      decoration: const InputDecoration(
                        labelText: 'Amount (MAD)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final amount = double.tryParse(
                          (value ?? '').trim().replaceAll(',', '.'),
                        );

                        if (amount == null || !amount.isFinite || amount <= 0) {
                          return 'Enter a valid amount above zero';
                        }
                        return null;
                      },
                      onSaved: (value) => amountText = value!.trim(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          refreshDialog(() => category = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  formKey.currentState!.save();

                  final amount = double.parse(amountText.replaceAll(',', '.'));

                  Navigator.pop(dialogContext, {
                    'title': title,
                    'category': category,
                    'amount': isIncome ? amount : -amount,
                    'date': transaction.date,
                  });
                },
                child: const Text('Save changes'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || !mounted) return;

    final index = transactions.indexWhere((item) => item.id == transaction.id);

    if (index == -1) return;

    final oldTransaction = transactions[index];

    final updatedTransaction = WalletTransaction(
      id: transaction.id,
      title: result['title'] as String,
      category: result['category'] as String,
      amount: result['amount'] as double,
      date: result['date'] as String,
    );

    setState(() {
      transactions[index] = updatedTransaction;
    });

    try {
      await _saveTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        transactions[index] = oldTransaction;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save changes. Please try again.'),
        ),
      );
    }
  }

  Future<void> _deleteTransaction(WalletTransaction transaction) async {
    final index = transactions.indexWhere((item) => item.id == transaction.id);

    if (index == -1) return;

    final deletedTransaction = transactions[index];

    setState(() {
      transactions.removeAt(index);
    });

    try {
      await _saveTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${deletedTransaction.title}" was deleted.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              _restoreDeletedTransaction(index, deletedTransaction);
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        transactions.insert(index, deletedTransaction);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save deletion. Please try again.'),
        ),
      );
    }
  }

  Future<void> _restoreDeletedTransaction(
    int index,
    WalletTransaction transaction,
  ) async {
    if (!mounted) return;

    setState(() {
      final safeIndex = index.clamp(0, transactions.length);
      transactions.insert(safeIndex, transaction);
    });

    try {
      await _saveTransactions();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        transactions.remove(transaction);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restore the transaction.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 22,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.green,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'DarnaWallet',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon.')),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.navy,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedIndex == 0
                ? _buildDashboard()
                : _buildOtherPage(),
          ),
        ),
      ),
      floatingActionButton: !isLoading && selectedIndex <= 1
          ? FloatingActionButton(
              onPressed: _addTransaction,
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.green,
              tooltip: 'Add transaction',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.green.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 90),
      children: [
        const Text(
          'Good day!',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        const Text(
          'Welcome to your wallet',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 23),
        _buildBalanceCard(),
        const SizedBox(height: 24),
        const Text(
          'Your overview',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Income',
                amount: '+${formatMoney(totalIncome)}',
                icon: Icons.arrow_downward_rounded,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Expenses',
                amount: '-${formatMoney(totalExpenses)}',
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFE78383),
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent transactions',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => selectedIndex = 1),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFF168866),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No transactions yet. Tap + to add one.'),
          )
        else
          ...transactions.take(4).map(_buildTransaction),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Demo data · No real money is involved',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF193A4D), AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total balance',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'MAD ${formatMoney(balance)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 27),
          Row(
            children: [
              Expanded(
                child: _quickAction(
                  icon: Icons.add_rounded,
                  label: 'Add income',
                  onTap: () => _addTransaction(initialIncome: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickAction(
                  icon: Icons.remove_rounded,
                  label: 'Add expense',
                  onTap: () => _addTransaction(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickAction(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onTap: () => _showComingSoon('More wallet actions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.green, size: 25),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 21,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MAD · All transactions',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaction(WalletTransaction transaction) {
    final double amount = transaction.amount;
    final bool isIncome = transaction.isIncome;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEFF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.green.withValues(alpha: 0.13)
                  : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _iconFor(transaction.category),
              color: isIncome ? const Color(0xFF168866) : AppColors.navy,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transaction.category,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.date,
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${isIncome ? '+' : '-'}${formatMoney(amount)}',
            style: TextStyle(
              color: isIncome ? const Color(0xFF168866) : AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPage() {
    if (selectedIndex == 1) {
      return TransactionManagementPage(
        transactions: transactions,
        onEdit: _editTransaction,
        onDelete: _deleteTransaction,
      );
    }

    if (selectedIndex == 2) {
      return StatisticsDashboard(transactions: transactions);
    }

    if (selectedIndex == 3) {
      return BudgetManagementPage(transactions: transactions);
    }

    return ProfilePage(
      transactions: transactions,
      onDataChanged: _loadTransactions,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be implemented in a future version.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
