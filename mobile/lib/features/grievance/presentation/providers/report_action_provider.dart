import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'grievance_provider.dart';

final locationServiceProvider = Provider((ref) => LocationService());
final mediaServiceProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MediaService(dioClient);
});

class ReportState {
  final bool isSubmitting;
  final String? error;

  ReportState({this.isSubmitting = false, this.error});
}

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    return ReportState();
  }

  Future<bool> deleteReport(String reportId) async {
    state = ReportState(isSubmitting: true);
    try {
      final repo = ref.read(grievanceRepositoryProvider);
      await repo.deleteReport(reportId);
      ref.invalidate(nearbyReportsProvider);
      state = ReportState();
      return true;
    } catch (e) {
      state = ReportState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateStatus(String reportId, String status) async {
    state = ReportState(isSubmitting: true);
    try {
      final repo = ref.read(grievanceRepositoryProvider);
      await repo.updateStatus(reportId, status);
      ref.invalidate(nearbyReportsProvider);
      state = ReportState();
      return true;
    } catch (e) {
      state = ReportState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateDetails(String reportId,
      {String? description, String? department}) async {
    state = ReportState(isSubmitting: true);
    try {
      final repo = ref.read(grievanceRepositoryProvider);
      await repo.updateDetails(reportId,
          description: description, department: department);
      ref.invalidate(nearbyReportsProvider);
      state = ReportState();
      return true;
    } catch (e) {
      state = ReportState(error: e.toString());
      return false;
    }
  }

  Future<bool> createReport() async {
    state = ReportState(isSubmitting: true);

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final locationService = ref.read(locationServiceProvider);
      final repo = ref.read(grievanceRepositoryProvider);

      // 1. Pick and compress image
      final image = await mediaService.pickAndCompressImage();
      if (image == null) {
        state = ReportState(); // Cancelled by user
        return false;
      }

      // 2. Upload to Cloudinary
      final imageUrl = await mediaService.uploadToCloudinary(image.path);
      if (imageUrl == null) {
        state = ReportState(error: 'Failed to upload image. Please try again.');
        return false;
      }

      // 3. Get location
      final location = await locationService.getCurrentLocation();

      // 4. Submit report
      await repo.submitReport(
        title: 'Quick Report',
        description: 'Reported via 1-tap camera.',
        latitude: location.latitude,
        longitude: location.longitude,
        imageUrl: imageUrl,
      );

      // 4. Refresh nearby reports
      ref.invalidate(nearbyReportsProvider);

      state = ReportState();
      return true;
    } catch (e) {
      state = ReportState(error: e.toString());
      return false;
    }
  }
}

final reportActionProvider = NotifierProvider<ReportNotifier, ReportState>(() {
  return ReportNotifier();
});
