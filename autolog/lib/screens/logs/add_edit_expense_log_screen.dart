import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/expense_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';

const _expenseCategories = [
  'Toll', 'Parking', 'Fine', 'Accessories',
  'Insurance Payment', 'Repairs', 'Loan EMI', 'Miscellaneous',
];

class AddEditExpenseLogScreen extends ConsumerStatefulWidget {
  const AddEditExpenseLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditExpenseLogScreen> createState() => _AddEditExpenseLogScreenState();
}

class _AddEditExpenseLogScreenState extends ConsumerState<AddEditExpenseLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _category = 'Toll';
  bool _loading = false;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedVehicleId == null) {
        final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
        if (vehicles.length == 1) setState(() => _selectedVehicleId = vehicles.first.id);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
    }

    setState(() => _loading = true);
    try {
      final log = ExpenseLog(
        id: widget.logId ?? newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        category: _category,
        amount: double.parse(_amountCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref.read(expenseLogProvider(_selectedVehicleId!).notifier).saveExpenseLog(log);

      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                widget.logId != null ? 'Edit Expense' : 'Add Expense',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vehicles.length > 1) ...[
                        _SectionHeader(title: 'Which vehicle?', icon: Icons.directions_car_rounded),
                        DropdownButtonFormField<String>(
                          value: _selectedVehicleId,
                          items: vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nickname))).toList(),
                          onChanged: (v) => setState(() => _selectedVehicleId = v),
                          decoration: _inputDecoration('Select Vehicle'),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _SectionHeader(title: 'Expense Category', icon: Icons.category_rounded),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _category = v!),
                        decoration: _inputDecoration('Type of Expense'),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Financials', icon: Icons.payments_rounded),
                      _buildTextField(
                        controller: _amountCtrl,
                        label: 'Amount Paid',
                        hint: '0.00',
                        suffixText: '₹',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.price,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Timing', icon: Icons.access_time_filled_rounded),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: cs.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.calendar_today_rounded, color: cs.primary, size: 20),
                        ),
                        title: Text(
                          'Spent on: ${DateFormatter.format(_date)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Notes', icon: Icons.notes_rounded),
                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Additional Info',
                        maxLines: 4,
                        hint: 'What was this expense for?',
                      ),
                      const SizedBox(height: 48),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withAlpha(50))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withAlpha(50))),
      filled: true,
      fillColor: cs.surface,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label).copyWith(
        hintText: hint,
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
          ),
        ],
      ),
    );
  }
}
