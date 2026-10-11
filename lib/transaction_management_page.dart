import 'package:flutter/material.dart';

const Color transactionNavy = Color(0xFF142B3B);
const Color transactionGreen = Color(0xFF35C995);

class TransactionManagementPage extends StatefulWidget {
  const TransactionManagementPage({
    super.key,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> transactions;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  State<TransactionManagementPage> createState() =>
      _TransactionManagementPageState();
}

class _TransactionManagementPageState extends State<TransactionManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  String _typeFilter = 'All';
  String? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _amount(Map<String, dynamic> transaction) {
    return (transaction['amount'] as num).toDouble();
  }

  List<String> get _categories {
    final categories = widget.transactions
        .map((transaction) => transaction['category'].toString())
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();

    return widget.transactions.where((transaction) {
      final title = transaction['title'].toString().toLowerCase();
      final category = transaction['category'].toString().toLowerCase();
      final amount = _amount(transaction);

      final matchesSearch =
          query.isEmpty || title.contains(query) || category.contains(query);

      final matchesType = switch (_typeFilter) {
        'Income' => amount > 0,
        'Expenses' => amount < 0,
        _ => true,
      };

      final matchesCategory =
          _categoryFilter == null ||
          transaction['category'].toString() == _categoryFilter;

      return matchesSearch && matchesType && matchesCategory;
    }).toList();
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

    if (value.contains('salary') ||
        value.contains('income') ||
        value.contains('business')) {
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

  Future<void> _confirmDelete(Map<String, dynamic> transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'Are you sure you want to delete '
          '"${transaction['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.onDelete(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final categories = _categories;
    final totalIncome = filtered
        .where((transaction) => _amount(transaction) > 0)
        .fold<double>(0, (sum, transaction) => sum + _amount(transaction));

    final totalExpenses = filtered
        .where((transaction) => _amount(transaction) < 0)
        .fold<double>(
          0,
          (sum, transaction) => sum + _amount(transaction).abs(),
        );

    final netAmount = totalIncome - totalExpenses;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 100),
      children: [
        const Text(
          'All activity',
          style: TextStyle(
            color: transactionNavy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.transactions.length} total transactions',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 20),

        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEBEFF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtered summary',
                style: TextStyle(
                  color: transactionNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Income',
                      '+${_money(totalIncome)}',
                      const Color(0xFF168866),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryItem(
                      'Expenses',
                      _money(totalExpenses),
                      transactionNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryItem(
                      'Net',
                      '${netAmount >= 0 ? '+' : '-'}${_money(netAmount)}',
                      netAmount >= 0
                          ? const Color(0xFF168866)
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Amounts in MAD; based on current search and filters.',
                style: TextStyle(color: Colors.black45, fontSize: 11),
              ),
            ],
          ),
        ),
        // Search field.
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search title or category...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEBEFF2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEBEFF2)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Income and expense filters.
        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(
              value: 'All',
              label: Text('All'),
              icon: Icon(Icons.list_alt),
            ),
            ButtonSegment<String>(
              value: 'Income',
              label: Text('Income'),
              icon: Icon(Icons.arrow_downward),
            ),
            ButtonSegment<String>(
              value: 'Expenses',
              label: Text('Expenses'),
              icon: Icon(Icons.arrow_upward),
            ),
          ],
          selected: {_typeFilter},
          onSelectionChanged: (selection) {
            setState(() => _typeFilter = selection.first);
          },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 12),

        // Category filter.
        DropdownButtonFormField<String>(
          initialValue: _categoryFilter,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Filter by category',
            prefixIcon: const Icon(Icons.category_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All categories'),
            ),
            ...categories.map(
              (category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _categoryFilter = value);
          },
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                color: transactionNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${filtered.length} found',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEBEFF2)),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off_rounded, size: 42, color: Colors.black38),
                SizedBox(height: 12),
                Text(
                  'No transactions found',
                  style: TextStyle(
                    color: transactionNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Try another search or change your filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          )
        else
          ...filtered.map(_buildTransactionCard),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = _amount(transaction);
    final isIncome = amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEFF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isIncome
                  ? transactionGreen.withValues(alpha: 0.14)
                  : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconFor(transaction['category'].toString()),
              color: isIncome ? const Color(0xFF168866) : transactionNavy,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'].toString(),
                  style: const TextStyle(
                    color: transactionNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['category'].toString(),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['date']?.toString() ?? '',
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  '${isIncome ? '+' : '-'}${_money(amount)} MAD',
                  style: TextStyle(
                    color: isIncome ? const Color(0xFF168866) : transactionNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Transaction actions',
            onSelected: (action) async {
              if (action == 'edit') {
                await widget.onEdit(transaction);
              } else if (action == 'delete') {
                await _confirmDelete(transaction);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

