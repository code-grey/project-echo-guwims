class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException([this.message = 'An unexpected error occurred', this.prefix]);

  @override
  String toString() {
    return "${prefix != null ? '$prefix: ' : ''}$message";
  }
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred'])
      : super(message, 'Network Exception');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized access'])
      : super(message, 'Unauthorized');
}

class BadRequestException extends AppException {
  BadRequestException([String message = 'Invalid request'])
      : super(message, 'Bad Request');
}

class ServerException extends AppException {
  ServerException([String message = 'Internal server error'])
      : super(message, 'Server Error');
}
