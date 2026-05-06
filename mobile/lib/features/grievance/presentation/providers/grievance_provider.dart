import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/grievance_report.dart';
import '../../data/repositories/grievance_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final grievanceRepositoryProvider = Provider<GrievanceRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return GrievanceRepository(dioClient);
});

// A simple provider to fetch nearby reports
final nearbyReportsProvider =
    FutureProvider.family<List<GrievanceReport>, Map<String, double>>(
        (ref, coords) async {
  final repo = ref.watch(grievanceRepositoryProvider);
  final user = ref.watch(authProvider).user;

  // Admins should see the global view, bypassing the 5km local geofence.
  if (user?.role == 'ADMIN') {
    return repo.getAllReports();
  }

  final lat = coords['lat']!;
  final lon = coords['lon']!;
  return repo.getNearbyReports(lat, lon);
});
