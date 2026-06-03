import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        final message = _friendlyMessage(error);
        final statusCode = error.response?.statusCode;
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: AppException(message: message, statusCode: statusCode),
            response: error.response,
            type: error.type,
          ),
        );
      },
    ));
  }

  Dio get dio => _dio;

  String _friendlyMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Please check your network.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your connection.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 400) return 'Bad request. Please check your input.';
        if (code == 401) return 'Unauthorized. Please log in again.';
        if (code == 403) return 'Access denied.';
        if (code == 404) return 'Resource not found.';
        if (code == 422) return 'Validation error from server.';
        if (code != null && code >= 500) return 'Server error ($code). Try again later.';
        return 'Unexpected server response ($code).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return error.message ?? 'An unexpected network error occurred.';
    }
  }
}
