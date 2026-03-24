import 'package:dio/dio.dart';

import 'api_client.dart';
import 'network_exceptions.dart';

/// POST helpers for `/api/v1/password/*` (no Bearer auth).
class PasswordApiHelper {
  PasswordApiHelper._();

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await ApiClient.passwordClient()
          .post<Map<String, dynamic>>(path, data: data);
      final body = response.data;
      if (body == null) {
        throw const NetworkException(message: 'Empty response body.');
      }
      return body;
    } on DioException catch (e) {
      if (e.error is NetworkException) throw e.error as NetworkException;
      throw NetworkException.fromDioError(e);
    }
  }
}
