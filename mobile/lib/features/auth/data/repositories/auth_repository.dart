import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthRepository {
  final DioClient _dioClient;
  final StorageService _storageService;

  AuthRepository(this._dioClient, this._storageService);

  Future<AuthResponse> login(String universityId, String pin) async {
    try {
      final response = await _dioClient.instance.post(
        '/api/auth/login',
        data: {
          'university_id': universityId,
          'pin': pin,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens
      await _storageService.saveAccessToken(authResponse.accessToken);
      await _storageService.saveRefreshToken(authResponse.refreshToken);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<User?> getCurrentUser() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _dioClient.instance.get('/api/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
