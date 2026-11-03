import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  Get.put(AppController(prefs));
  runApp(const ExpenseTrackerApp());
}

class AppController extends GetxController {
  AppController(this.prefs);
  final SharedPreferences prefs;
  final transactions = <Map<String, dynamic>>[].obs;
  final isDark = false.obs;
  final userName = 'Guest User'.obs;
  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void onInit() {
    super.onInit();
    isDark.value = prefs.getBool('dark_mode') ?? false;
    userName.value = prefs.getString('user_name') ?? 'Guest User';
    final raw = prefs.getString('transactions');
    if (raw != null) {
      try {
        transactions.assignAll((jsonDecode(raw) as List).cast<Map<String, dynamic>>());
      } catch (_) {
        transactions.clear();
      }
    }
  }

  Future<void> save() async {
    await prefs.setString('transactions', jsonEncode(transactions));
  }

  Future<void> addTransaction(String title, double amount, String category, bool income) async {
    transactions.insert(0, {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'amount': amount,
      'category': category,
      'income': income,
      'date': DateTime.now().toIso8601String(),
    });
    await save();
  }

  double get totalIncome => transactions.where((e) => e['income'] == true)
      .fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());
  double get totalExpense => transactions.where((e) => e['income'] != true)
      .fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());
  double get balance => totalIncome - totalExpense;

  Future<void> toggleTheme() async {
    isDark.toggle();
    await prefs.setBool('dark_mode', isDark.value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setUser(String name) async {
    userName.value = name;
    await prefs.setString('user_name', name);
  }

  Future<void> clearTransactions() async {
    transactions.clear();
    await save();
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Expense Tracker',
      themeMode: c.isDark.value ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4263EB), useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB), appBarTheme: const AppBarTheme(centerTitle: false)),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF8EA2FF), brightness: Brightness.dark, useMaterial3: true),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashPage()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/register', page: () => const RegisterPage()),
        GetPage(name: '/home', page: () => const DashboardPage()),
        GetPage(name: '/add', page: () => const AddTransactionPage()),
        GetPage(name: '/history', page: () => const HistoryPage()),
        GetPage(name: '/summary', page: () => const SummaryPage()),
        GetPage(name: '/profile', page: () => const ProfilePage()),
      ],
    ));
  }
}

final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String dateLabel(dynamic value) {
  final d = DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  return DateFormat('dd MMM yyyy').format(d);
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  @override void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () => Get.offNamed('/login'));
  }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_wallet_rounded, size: 52)),
      const SizedBox(height: 18), Text('Smart Expense Tracker',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), const Text('Manage money, make better decisions'),
      const SizedBox(height: 24), const CircularProgressIndicator(),
    ])));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final name = TextEditingController();
  @override void dispose() { name.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AuthScaffold(
    title: 'Welcome back', subtitle: 'Enter your name to continue',
    child: Column(children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
        final n = name.text.trim();
        if (n.isEmpty) { Get.snackbar('Name required', 'Please enter your name.'); return; }
        await Get.find<AppController>().setUser(n);
        Get.offAllNamed('/home');
      }, child: const Text('Continue'))),
      TextButton(onPressed: () => Get.toNamed('/register'), child: const Text('Create a profile')),
    ]));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  @override void dispose() { name.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AuthScaffold(
    title: 'Create profile', subtitle: 'Set up your expense tracker',
    child: Column(children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
        final n = name.text.trim();
        if (n.isEmpty) { Get.snackbar('Name required', 'Please enter your name.'); return; }
        await Get.find<AppController>().setUser(n);
        Get.offAllNamed('/home');
      }, child: const Text('Create account'))),
      TextButton(onPressed: () => Get.back(), child: const Text('Back to login')),
    ]));
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child});
  final String title, subtitle; final Widget child;
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
      child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.account_balance_wallet, size: 48), const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center),
        const SizedBox(height: 28), child,
      ])))))));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Overview'), actions: [
        IconButton(onPressed: () => Get.toNamed('/profile'), icon: const Icon(Icons.account_circle_outlined)),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Get.toNamed('/add'),
        icon: const Icon(Icons.add), label: const Text('Transaction')),
      body: Obx(() => ListView(padding: const EdgeInsets.all(18), children: [
        Text('Hello, ${c.userName.value} 👋', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Available balance'), const SizedBox(height: 8),
          Text(money.format(c.balance), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 18), Row(children: [
            Expanded(child: _miniMetric(context, 'Income', c.totalIncome, Icons.arrow_downward, Colors.green)),
            Expanded(child: _miniMetric(context, 'Expenses', c.totalExpense, Icons.arrow_upward, Colors.red)),
          ])
        ]))),
        const SizedBox(height: 20), SectionHeading('Quick actions'),
        const SizedBox(height: 10), Row(children: [
          Expanded(child: _action(context, Icons.add_circle_outline, 'Add entry', '/add')),
          const SizedBox(width: 10), Expanded(child: _action(context, Icons.receipt_long, 'History', '/history')),
          const SizedBox(width: 10), Expanded(child: _action(context, Icons.pie_chart_outline, 'Summary', '/summary')),
        ]),
        const SizedBox(height: 22), SectionHeading('Recent transactions', action: 'See all', onTap: () => Get.toNamed('/history')),
        const SizedBox(height: 8),
        if (c.transactions.isEmpty) const EmptyState(message: 'No transactions yet. Add your first income or expense.')
        else ...c.transactions.take(5).map((t) => TransactionTile(item: t)),
        const SizedBox(height: 80),
      ])),
    );
  }
}

Widget _miniMetric(BuildContext context, String label, double amount, IconData icon, Color color) => Row(children: [
  Icon(icon, color: color), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label), Text(money.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
  ]))
]);
Widget _action(BuildContext context, IconData icon, String label, String route) => Card(child: InkWell(
  borderRadius: BorderRadius.circular(12), onTap: () => Get.toNamed(route),
  child: Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6), child: Column(children: [
    Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 7),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  ]))));
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onTap});
  final String title; final String? action; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
  ]);
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});
  @override State<AddTransactionPage> createState() => _AddTransactionPageState();
}
class _AddTransactionPageState extends State<AddTransactionPage> {
  final title = TextEditingController(), amount = TextEditingController();
  bool income = false; String category = 'Food';
  final categories = ['Food', 'Travel', 'Shopping', 'Bills', 'Health', 'Salary', 'Other'];
  @override void dispose() { title.dispose(); amount.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Add transaction')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      SegmentedButton<bool>(segments: const [
        ButtonSegment(value: false, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
        ButtonSegment(value: true, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
      ], selected: {income}, onSelectionChanged: (s) => setState(() => income = s.first)),
      const SizedBox(height: 18),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Grocery shopping', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
        items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? 'Other')),
      const SizedBox(height: 22),
      FilledButton.icon(onPressed: () async {
        final t = title.text.trim(), a = double.tryParse(amount.text.trim());
        if (t.isEmpty || a == null || a <= 0) { Get.snackbar('Invalid details', 'Enter a title and a valid amount.'); return; }
        await Get.find<AppController>().addTransaction(t, a, category, income);
        Get.back(); Get.snackbar('Saved', 'Transaction added successfully.');
      }, icon: const Icon(Icons.save), label: const Text('Save transaction')),
    ]));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Scaffold(appBar: AppBar(title: const Text('Transaction history')),
      body: Obx(() => c.transactions.isEmpty ? const EmptyState(message: 'Your transactions will appear here.')
        : ListView.separated(padding: const EdgeInsets.all(16), itemCount: c.transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => TransactionTile(item: c.transactions[i]))));
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});
  final Map<String, dynamic> item;
  @override Widget build(BuildContext context) {
    final isIncome = item['income'] == true;
    final amount = (item['amount'] as num).toDouble();
    return Card(child: ListTile(
      leading: CircleAvatar(child: Icon(isIncome ? Icons.south_west : Icons.north_east,
        color: isIncome ? Colors.green : Colors.red)),
      title: Text(item['title']?.toString() ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${item['category']} • ${dateLabel(item['date'])}'),
      trailing: Text('${isIncome ? '+' : '-'}${money.format(amount)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),
    ));
  }
}

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});
  @override Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Scaffold(appBar: AppBar(title: const Text('Monthly summary')),
      body: Obx(() {
        final now = DateTime.now();
        final monthItems = c.transactions.where((t) {
          final d = DateTime.tryParse(t['date'].toString());
          return d != null && d.year == now.year && d.month == now.month;
        }).toList();
        double sum(bool inc) => monthItems.where((t) => t['income'] == inc)
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
        final inc = sum(true), exp = sum(false);
        return ListView(padding: const EdgeInsets.all(18), children: [
          Text(DateFormat('MMMM yyyy').format(now), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _summaryCard(context, 'Income this month', inc, Colors.green, Icons.trending_up),
          _summaryCard(context, 'Expenses this month', exp, Colors.red, Icons.trending_down),
          _summaryCard(context, 'Net savings', inc - exp, Theme.of(context).colorScheme.primary, Icons.savings_outlined),
          const SizedBox(height: 12), const Text('Category breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (monthItems.isEmpty) const EmptyState(message: 'No activity recorded this month.')
          else ..._categoryRows(monthItems),
        ]);
      }));
  }
  List<Widget> _categoryRows(List<Map<String, dynamic>> items) {
    final totals = <String, double>{};
    for (final t in items.where((e) => e['income'] != true)) {
      final key = t['category'].toString();
      totals[key] = (totals[key] ?? 0) + (t['amount'] as num).toDouble();
    }
    return totals.entries.map((e) => Card(child: ListTile(title: Text(e.key), trailing: Text(money.format(e.value))))).toList();
  }
  Widget _summaryCard(BuildContext context, String label, double value, Color color, IconData icon) =>
    Card(child: ListTile(leading: Icon(icon, color: color, size: 30), title: Text(label),
      subtitle: Text(money.format(value), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Scaffold(appBar: AppBar(title: const Text('Profile & settings')),
      body: Obx(() => ListView(padding: const EdgeInsets.all(18), children: [
        CircleAvatar(radius: 38, child: Text(c.userName.value.isEmpty ? 'U' : c.userName.value[0].toUpperCase(), style: const TextStyle(fontSize: 28))),
        const SizedBox(height: 12), Center(child: Text(c.userName.value, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 24),
        Card(child: SwitchListTile(title: const Text('Dark mode'), subtitle: const Text('Change app appearance'),
          secondary: const Icon(Icons.dark_mode_outlined), value: c.isDark.value, onChanged: (_) => c.toggleTheme())),
        Card(child: ListTile(leading: const Icon(Icons.person_outline), title: const Text('Edit display name'),
          onTap: () async {
            final ctrl = TextEditingController(text: c.userName.value);
            final result = await Get.dialog<String>(AlertDialog(title: const Text('Display name'),
              content: TextField(controller: ctrl, autofocus: true),
              actions: [TextButton(onPressed: Get.back, child: const Text('Cancel')),
                FilledButton(onPressed: () => Get.back(result: ctrl.text.trim()), child: const Text('Save'))]));
            if (result != null && result.isNotEmpty) c.setUser(result);
          })),
        Card(child: ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Clear all transactions'),
          onTap: () => Get.dialog(AlertDialog(title: const Text('Clear data?'),
            content: const Text('This removes all saved transactions from this device.'),
            actions: [TextButton(onPressed: Get.back, child: const Text('Cancel')),
              FilledButton(onPressed: () { c.clearTransactions(); Get.back(); }, child: const Text('Clear'))])))),
        const SizedBox(height: 20), const Center(child: Text('Smart Expense Tracker • Version 1.0.0')),
      ])));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});
  final String message;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(30),
    child: Column(children: [Icon(Icons.receipt_long_outlined, size: 42, color: Theme.of(context).colorScheme.outline),
      const SizedBox(height: 10), Text(message, textAlign: TextAlign.center)]));
}
