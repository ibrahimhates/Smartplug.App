import '../enums/api_error_type.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  final ApiErrorType? errorType;

  ApiResponse({
    this.data,
    this.error,
    required this.success,
    this.errorType,
  });

  factory ApiResponse.success(T? data) {
    return ApiResponse(
      data: data,
      success: true,
    );
  }

  factory ApiResponse.error(String error, {ApiErrorType? errorType}) {
    return ApiResponse(
      error: error,
      success: false,
      errorType: errorType,
    );
  }
}

class NoContent {
  NoContent();
}
