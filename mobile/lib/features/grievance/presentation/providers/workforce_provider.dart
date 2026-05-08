import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/grievance_report.dart';
import 'grievance_provider.dart';
import 'report_action_provider.dart'; // For media and location providers

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
      final mediaService = ref.read(mediaServiceProvider);
      final locationService = ref.read(locationServiceProvider);
      final repo = ref.read(grievanceRepositoryProvider);

      // 1. Get GPS Location First (Anti-Fraud check)
      final location = await locationService.getCurrentLocation();

      // 2. Take "After" photo
      final image = await mediaService.pickAndCompressImage();
      if (image == null) {
        state = const AsyncValue.data(null); // Cancelled
        return;
      }

      // 3. Upload to Cloudinary
      final imageUrl = await mediaService.uploadToCloudinary(image.path);
      if (imageUrl == null) {
        throw Exception('Failed to upload proof image');
      }

      // 4. Update status with Proof of Work
      await repo.updateStatus(
        reportId,
        'RESOLVED',
        workerLat: location.latitude,
        workerLng: location.longitude,
        afterImageUrl: imageUrl,
      );

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
