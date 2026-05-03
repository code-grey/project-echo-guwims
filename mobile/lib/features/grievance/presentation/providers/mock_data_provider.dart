import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/grievance_report.dart';

final mockReportsProvider = Provider<List<GrievanceReport>>((ref) {
  // Strictly instantiating the model ensures 100% compliance with the data spec.
  return [
    GrievanceReport(
      id: 'TCK-001',
      reporterId: 'dummy-id-1',
      status: 'REPORTED',
      aiDescription:
          'Accumulated plastic waste near the Science Block entrance.',
      aiDepartment: 'ESTATE',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      latitude: 26.1552,
      longitude: 91.6625,
      // imageUrl: null, // Testing nullable image
    ),
    GrievanceReport(
      id: 'TCK-002',
      reporterId: 'dummy-id-2',
      status: 'DISPATCHED',
      aiDescription: 'Overflowing dustbin in front of the Library.',
      aiDepartment: 'ESTATE',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      latitude: 26.1540,
      longitude: 91.6630,
      imageUrl: 'https://via.placeholder.com/150', // Mock URL
    ),
    GrievanceReport(
      id: 'TCK-003',
      reporterId: 'dummy-id-3',
      status: 'RESOLVED',
      aiDescription: 'Biomedical waste disposed incorrectly near lab.',
      aiDepartment: 'UNKNOWN',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      latitude: 26.1560,
      longitude: 91.6610,
    ),
  ];
});
