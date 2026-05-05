import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/grievance_report.dart';

class GrievanceRepository {
  final DioClient _dioClient;

  GrievanceRepository(this._dioClient);

  Future<void> submitReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String imagePath,
  }) async {
    final metadata = {
      'title': title,
      'description': description,
    };

    final formData = FormData.fromMap({
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'metadata': jsonEncode(metadata),
      'image': await MultipartFile.fromFile(imagePath),
    });

    await _dioClient.instance.post(
      '/api/reports',
      data: formData,
    );
  }

  Future<List<GrievanceReport>> getNearbyReports(double lat, double lon,
      {double radius = 5000}) async {
    final response = await _dioClient.instance.get(
      '/api/reports/nearby',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'radius': radius,
      },
    );

    // The backend returns a direct array of reports, not nested in a 'data' key as per report.go
    final List<dynamic> data = response.data ?? [];
    return data.map((json) => GrievanceReport.fromJson(json)).toList();
  }

  Future<List<GrievanceReport>> getWorkforceQueue() async {
    final response = await _dioClient.instance.get('/api/reports/queue');
    final List<dynamic> data = response.data ?? [];
    return data.map((json) => GrievanceReport.fromJson(json)).toList();
  }

  Future<List<GrievanceReport>> getAllReports() async {
    final response = await _dioClient.instance.get('/api/reports/all');
    final List<dynamic> data = response.data ?? [];
    return data.map((json) => GrievanceReport.fromJson(json)).toList();
  }

  Future<void> updateStatus(String ticketId, String status) async {
    await _dioClient.instance.put('/api/reports/update-status', data: {
      'report_id':
          ticketId, // The backend expects report_id based on UpdateStatus
      'status': status,
    });
  }

  Future<void> deleteReport(String reportId) async {
    await _dioClient.instance.delete('/api/reports/delete', queryParameters: {
      'id': reportId,
    });
  }

  Future<void> updateDetails(String reportId,
      {String? description, String? department}) async {
    final Map<String, dynamic> data = {'report_id': reportId};
    if (description != null) data['description'] = description;
    if (department != null) data['department'] = department;

    await _dioClient.instance.put('/api/reports/update', data: data);
  }
}
