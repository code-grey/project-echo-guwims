import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/grievance_report.dart';
import 'grievance_provider.dart';

/// Provider to fetch the departmental queue for the logged-in worker.
final workforceQueueProvider = FutureProvider<List<GrievanceReport>>((ref) async {
  final repo = ref.watch(grievanceRepositoryProvider);
  return repo.getWorkforceQueue();
});

/// Provider to fetch all reports for the Admin dashboard.
final adminReportsProvider = FutureProvider<List<GrievanceReport>>((ref) async {
  final repo = ref.watch(grievanceRepositoryProvider);
  return repo.getAllReports();
});

/// Notifier to manage the resolution state of a specific report.
class WorkforceNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> resolveReport(String reportId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(grievanceRepositoryProvider);
      await repo.updateStatus(reportId, 'RESOLVED');

      // Refresh the queue after successful resolution
      ref.invalidate(workforceQueueProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final workforceNotifierProvider = NotifierProvider<WorkforceNotifier, AsyncValue<void>>(() {
  return WorkforceNotifier();
});
