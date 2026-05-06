import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../errors/custom_exceptions.dart';

class DioClient {
  late final Dio _dio;
  final StorageService _storageService;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _refreshQueue = [];

  DioClient(this._storageService,
      {String baseUrl = 'http://192.168.0.114:8080'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await _storageService.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final isAuthEndpoint =
            e.requestOptions.path.contains('/api/auth/login') ||
                e.requestOptions.path.contains('/api/auth/refresh');

        if (e.response?.statusCode == 401 && !isAuthEndpoint) {
          // Token expired, attempt to refresh
          return _handleTokenRefresh(e, handler);
        }
        return handler.next(_mapDioException(e));
      },
    ));
  }

  Future<void> _handleTokenRefresh(
      DioException e, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      // Add to queue and wait
      _refreshQueue.add({'options': e.requestOptions, 'handler': handler});
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        throw UnauthorizedException('No refresh token available');
      }

      // Call refresh endpoint directly to avoid interceptor loop
      final response = await Dio().post(
        '${_dio.options.baseUrl}/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      if (newAccessToken != null && newRefreshToken != null) {
        await _storageService.saveAccessToken(newAccessToken);
        await _storageService.saveRefreshToken(newRefreshToken);

        // Retry original request
        e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(e.requestOptions);
        handler.resolve(retryResponse);

        // Process queue
        for (var queued in _refreshQueue) {
          final options = queued['options'] as RequestOptions;
          final queuedHandler = queued['handler'] as ErrorInterceptorHandler;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          try {
            final qResponse = await _dio.fetch(options);
            queuedHandler.resolve(qResponse);
          } catch (qErr) {
            if (qErr is DioException) {
              queuedHandler.reject(qErr);
            }
          }
        }
      } else {
        throw UnauthorizedException(
            'Failed to parse tokens from refresh response');
      }
    } catch (refreshErr) {
      await _storageService.clearAll();
      for (var queued in _refreshQueue) {
        final queuedHandler = queued['handler'] as ErrorInterceptorHandler;
        final options = queued['options'] as RequestOptions;
        queuedHandler.reject(DioException(
            requestOptions: options,
            error: UnauthorizedException('Session expired')));
      }
      handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: UnauthorizedException('Session expired')));
    } finally {
      _isRefreshing = false;
      _refreshQueue.clear();
    }
  }

  DioException _mapDioException(DioException e) {
    AppException customException;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        customException = NetworkException('Connection failed');
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          customException = BadRequestException(e.response?.data['error'] ??
              e.response?.data['message'] ??
              'Bad Request');
        } else if (statusCode == 401 || statusCode == 403) {
          customException = UnauthorizedException(e.response?.data['error'] ??
              e.response?.data['message'] ??
              'Unauthorized');
        } else if (statusCode != null && statusCode >= 500) {
          customException = ServerException('Server error: $statusCode');
        } else {
          customException = AppException('Unexpected error: $statusCode');
        }
        break;
      default:
        customException = AppException(e.message ?? 'Unknown error occurred');
    }
    return DioException(
      requestOptions: e.requestOptions,
      response: e.response,
      type: e.type,
      error: customException,
    );
  }

  Dio get instance => _dio;
}
