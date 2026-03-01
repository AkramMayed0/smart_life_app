import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _supabase = Supabase.instance.client;

  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> expenses = [];
  double totalExpenses = 0;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    double total = 0;
    for (var e in response) {
      total += (e['amount'] as num).toDouble();
    }

    setState(() {
      expenses = List<Map<String, dynamic>>.from(response);
      totalExpenses = total;
    });
  }

  double get todayTotal {
    final now = DateTime.now();
    return expenses
        .where((e) {
          final d = DateTime.parse(e['created_at']);
          return d.year == now.year && d.month == now.month && d.day == now.day;
        })
        .fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());
  }

  double get monthTotal {
    final now = DateTime.now();
    return expenses
        .where((e) {
          final d = DateTime.parse(e['created_at']);
          return d.year == now.year && d.month == now.month;
        })
        .fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _categoryController.text.isEmpty) return;

    await _supabase.from('expenses').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'amount': amount,
      'category': _categoryController.text,
      'description': _descriptionController.text,
      'created_at': DateTime.now().toIso8601String(),
    });

    _amountController.clear();
    _categoryController.clear();
    _descriptionController.clear();

    if (!mounted) return;
    Navigator.pop(context);
    _loadExpenses();
  }

  Future<void> _deleteExpense(String id) async {
    final index = expenses.indexWhere((e) => e['id'] == id);
    final removed = expenses[index];

    setState(() {
      expenses.removeAt(index);
      totalExpenses -= (removed['amount'] as num).toDouble();
    });

    await _supabase.from('expenses').delete().eq('id', id);
  }

  void _showAddExpenseDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Expense',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _field(
                _amountController,
                'Amount',
                Icons.attach_money,
                TextInputType.number,
              ),
              const SizedBox(height: 12),
              _field(_categoryController, 'Category', Icons.category),
              const SizedBox(height: 12),
              _field(_descriptionController, 'Description', Icons.description),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                      onPressed: _addExpense,
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final filteredExpenses = selectedCategory == null
        ? expenses
        : expenses
              .where(
                (e) =>
                    e['category'].toLowerCase() ==
                    selectedCategory!.toLowerCase(),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _summary('Total', totalExpenses, colors.primary),
                const SizedBox(width: 12),
                _summary('Today', todayTotal, colors.secondary),
                const SizedBox(width: 12),
                _summary('Month', monthTotal, colors.tertiary),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(null, 'All'),
                _chip('food', 'Food'),
                _chip('transport', 'Transport'),
                _chip('shopping', 'Shopping'),
                _chip('bills', 'Bills'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadExpenses,
              child: filteredExpenses.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text('No expenses yet'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, i) {
                        final e = filteredExpenses[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Slidable(
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _deleteExpense(e['id']),
                                  backgroundColor: Colors.red,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colors.primary,
                                  child: Icon(
                                    _icon(e['category']),
                                    color: colors.onPrimary,
                                  ),
                                ),
                                title: Text(e['category']),
                                subtitle: Text(
                                  e['description'] ?? 'No description',
                                ),
                                trailing: Text(
                                  '\$${e['amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(String title, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String? value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedCategory == value,
        onSelected: (_) => setState(() => selectedCategory = value),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, [
    TextInputType type = TextInputType.text,
  ]) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _icon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }
}
