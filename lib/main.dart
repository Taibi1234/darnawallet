
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DarnaWalletApp());
}

const Color navy = Color(0xFF142B3B);
const Color green = Color(0xFF35C995);
const Color background = Color(0xFFF5F7F9);
const double openingBalance = 6426.50;
const String storageKey = 'darnawallet_transactions';

class DarnaWalletApp extends StatelessWidget {
  const DarnaWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarnaWallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: navy,
          surface: Colors.white,
        ),
        fontFamily: 'Arial',
      ),
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

  List<Map<String, dynamic>> transactions = [];

  final List<Map<String, dynamic>> sampleTransactions = [
    {
      'title': 'Grocery shopping',
      'category': 'Food & groceries',
      'amount': -245.50,
      'date': 'Today, 10:42 AM',
    },
    {
      'title': 'Monthly salary',
      'category': 'Salary',
      'amount': 6500.00,
      'date': 'Today, 08:15 AM',
    },
    {
      'title': 'Coffee shop',
      'category': 'Food & drinks',
      'amount': -32.00,
      'date': 'Yesterday, 04:30 PM',
    },
    {
      'title': 'Internet bill',
      'category': 'Utilities',
      'amount': -199.00,
      'date': 'Yesterday, 11:20 AM',
    },
  ];

  double get totalIncome => transactions.fold<double>(
        0,
        (total, transaction) {
          final amount = (transaction['amount'] as num).toDouble();
          return total + (amount > 0 ? amount : 0);
        },
      );

  double get totalExpenses => transactions.fold<double>(
        0,
        (total, transaction) {
          final amount = (transaction['amount'] as num).toDouble();
          return total + (amount < 0 ? amount.abs() : 0);
        },
      );

  double get balance => openingBalance + totalIncome - totalExpenses;

  String get pageTitle {
    switch (selectedIndex) {
      case 1:
        return 'Transactions';
      case 2:
        return 'Statistics';
      case 3:
        return 'My profile';
      default:
        return 'My wallet';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(storageKey);

      List<Map<String, dynamic>> loadedTransactions;

      if (savedData == null) {
        loadedTransactions = sampleTransactions
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        await prefs.setString(storageKey, jsonEncode(loadedTransactions));
      } else {
        final decoded = jsonDecode(savedData) as List<dynamic>;

        loadedTransactions = decoded.map((item) {
          final transaction = Map<String, dynamic>.from(item as Map);
          transaction['amount'] =
              (transaction['amount'] as num).toDouble();
          return transaction;
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
        transactions = sampleTransactions
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
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
    await prefs.setString(storageKey, jsonEncode(transactions));
  }

  String _money(double amount) {
    final parts = amount.abs().toStringAsFixed(2).split('.');
    final digits = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return '${buffer.toString()}.${parts[1]}';
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
                            category =
                                isIncome ? 'Salary' : 'Food & groceries';
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
                      'date': 'Added just now',
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

    setState(() {
      transactions.insert(0, result);
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
        const SnackBar(
          content: Text('Transaction added, but saving failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        titleSpacing: 22,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: green,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'DarnaWallet',
              style: TextStyle(
                color: navy,
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
                const SnackBar(
                  content: Text('Notifications coming soon.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
            color: navy,
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
              backgroundColor: navy,
              foregroundColor: green,
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
        indicatorColor: green.withValues(alpha: 0.18),
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
            color: navy,
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
            color: navy,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Income',
                amount: '+${_money(totalIncome)}',
                icon: Icons.arrow_downward_rounded,
                color: green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Expenses',
                amount: '-${_money(totalExpenses)}',
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
                color: navy,
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
          colors: [Color(0xFF193A4D), navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
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
              'MAD ${_money(balance)}',
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
            Icon(icon, color: green, size: 25),
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
                color: navy,
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

  Widget _buildTransaction(Map<String, dynamic> transaction) {
    final double amount = (transaction['amount'] as num).toDouble();
    final bool isIncome = amount > 0;

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
                  ? green.withValues(alpha: 0.13)
                  : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _iconFor(transaction['category'] as String),
              color: isIncome ? const Color(0xFF168866) : navy,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'] as String,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transaction['category'] as String,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction['date'] as String,
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${isIncome ? '+' : '-'}${_money(amount)}',
            style: TextStyle(
              color: isIncome ? const Color(0xFF168866) : navy,
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
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 90),
        children: [
          const Text(
            'All activity',
            style: TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          if (transactions.isEmpty)
            const Text('No transactions yet. Tap + to add one.')
          else
            ...transactions.map(_buildTransaction),
        ],
      );
    }

    final String description = selectedIndex == 2
        ? 'Your income and expenses are calculated from your saved transactions. More spending insights are coming soon.'
        : 'Your account settings and preferences will appear here.';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selectedIndex == 2
                ? Icons.bar_chart_rounded
                : Icons.person_outline_rounded,
            color: green,
            size: 64,
          ),
          const SizedBox(height: 18),
          Text(
            pageTitle,
            style: const TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() => selectedIndex = 0),
            child: const Text('Back to wallet'),
          ),
        ],
      ),
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
