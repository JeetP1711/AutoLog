import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'vehicle_provider.dart';

class ExpenseLogNotifier extends FamilyAsyncNotifier<List<ExpenseLog>, String> {
  @override
  Future<List<ExpenseLog>> build(String vehicleId) async {
    return ref.read(expenseLogRepositoryProvider).getByVehicle(vehicleId);
  }

  Future<void> saveExpenseLog(ExpenseLog log) async {
    final repo = ref.read(expenseLogRepositoryProvider);
    await repo.save(log);
    state = AsyncData(await repo.getByVehicle(log.vehicleId));
  }

  Future<void> deleteExpenseLog(String logId) async {
    final repo = ref.read(expenseLogRepositoryProvider);
    await repo.delete(logId);
    state = AsyncData(await repo.getByVehicle(arg));
  }
}

final expenseLogProvider =
    AsyncNotifierProviderFamily<ExpenseLogNotifier, List<ExpenseLog>, String>(
  ExpenseLogNotifier.new,
);

final allExpenseLogsProvider = FutureProvider<List<ExpenseLog>>((ref) async {
  return ref.read(expenseLogRepositoryProvider).getAll();
});
