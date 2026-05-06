import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(validateStatus: (status) => status! < 500));
  
  // Note: We might need a valid Admin JWT token for this route if auth is enabled.
  // We'll see what the server responds with first.
  final formData = FormData.fromMap({
    'csv': await MultipartFile.fromFile('../backend/test_import.csv'),
  });

  try {
    final response = await dio.post(
      'http://localhost:8080/api/admin/users/import',
      data: formData,
    );
    print("Status: ${response.statusCode}");
    print("Data: ${response.data}");
  } on DioException catch (e) {
    print(e.response?.data ?? e.message);
  }
}