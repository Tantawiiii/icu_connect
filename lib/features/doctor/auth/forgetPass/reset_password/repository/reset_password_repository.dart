import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/network/password_api_helper.dart';

import '../data/reset_password_response.dart';

class ResetPasswordRepository {
  Future<ResetPasswordFlowResponse> reset({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final json = await PasswordApiHelper.post(
        ApiConstants.passwordReset,
        data: {
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return ResetPasswordFlowResponse.fromJson(json);
    } on NetworkException {
      rethrow;
    }
  }
}
