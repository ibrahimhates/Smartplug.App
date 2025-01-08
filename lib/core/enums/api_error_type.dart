enum ApiErrorType {
  unauthorized,
  networkError,
  serverError,
  unknown;

  static ApiErrorType fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
        return ApiErrorType.unauthorized;
      case 500:
        return ApiErrorType.serverError;
      default:
        return ApiErrorType.unknown;
    }
  }
}
