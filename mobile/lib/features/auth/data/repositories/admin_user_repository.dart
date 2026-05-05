import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user.dart';

class AdminUserRepository {
  final DioClient _dioClient;

  AdminUserRepository(this._dioClient);

  Future<List<User>> getAllUsers() async {
    final response = await _dioClient.instance.get('/api/admin/users');
    final List<dynamic> data = response.data ?? [];
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User> createUser({
    required String universityId,
    required String pin,
    required String role,
  }) async {
    final response = await _dioClient.instance.post(
      '/api/admin/users',
      data: {
        'university_id': universityId,
        'pin': pin,
        'role': role,
      },
    );
    return User.fromJson(response.data);
  }

  Future<void> deleteUser(String userId) async {
    await _dioClient.instance.delete(
      '/api/admin/users',
      queryParameters: {'id': userId},
    );
  }

  Future<Map<String, dynamic>> importUsersCsv(String filePath) async {
    final formData = FormData.fromMap({
      'csv': await MultipartFile.fromFile(filePath),
    });

    final response = await _dioClient.instance.post(
      '/api/admin/users/import',
      data: formData,
    );
    
    return {
      'message': response.data['message'],
      'count': response.data['count'],
    };
  }
}
