
import 'package:flutter/material.dart';

void main() {
  runApp(const DarnaWalletApp());
}

const Color navy = Color(0xFF142B3B);
const Color green = Color(0xFF35C995);
const Color background = Color(0xFFF5F7F9);

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

  final List<Map<String, dynamic>> transactions = [
    {
      'title': 'Grocery shopping',
      'category': 'Food & groceries',
      'amount': -245.50,
      'icon': Icons.shopping_basket_outlined,
      'date': 'Today, 10:42 AM',
    },
    {
      'title': 'Monthly salary',
      'category': 'Income',
      'amount': 6500.00,
      'icon': Icons.account_balance_wallet_outlined,
      'date': 'Today, 08:15 AM',
    },
    {
      'title': 'Coffee shop',
      'category': 'Food & drinks',
      'amount': -32.00,
      'icon': Icons.local_cafe_outlined,
      'date': 'Yesterday, 04:30 PM',
    },
    {
      'title': 'Internet bill',
      'category': 'Utilities',
      'amount': -199.00,
      'icon': Icons.wifi_outlined,
      'date': 'Yesterday, 11:20 AM',
    },
  ];

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
            child: selectedIndex == 0
                ? _buildDashboard()
                : _buildOtherPage(),
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      children: [
        const Text(
          'Good day ðŸ‘‹',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
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
                amount: '+6,500.00',
                icon: Icons.arrow_downward_rounded,
                color: green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Expenses',
                amount: '-476.50',
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
        ...transactions.take(4).map(_buildTransaction),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Demo data Â· No real money is involved',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total balance',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              Icon(
                Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'MAD 12,450.00',
              style: TextStyle(
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
                  label: 'Add money',
                  onTap: () => _showComingSoon('Add money'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickAction(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  onTap: () => _showComingSoon('Transfers'),
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
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
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
            'MAD Â· This month',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaction(Map<String, dynamic> transaction) {
    final double amount = transaction['amount'] as double;
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
              transaction['icon'] as IconData,
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
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction['date'] as String,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${isIncome ? '+' : '-'}${amount.abs().toStringAsFixed(2)}',
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
        padding: const EdgeInsets.all(22),
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
          ...transactions.map(_buildTransaction),
        ],
      );
    }

    final String description = selectedIndex == 2
        ? 'Your spending insights will appear here as your wallet develops.'
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

