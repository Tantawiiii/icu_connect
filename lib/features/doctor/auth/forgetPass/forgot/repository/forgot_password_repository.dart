import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/network/password_api_helper.dart';

import '../data/forgot_password_response.dart';

class ForgotPasswordRepository {
  Future<ForgotPasswordResponse> requestOtp({required String email}) async {
    try {
      final json = await PasswordApiHelper.post(
        ApiConstants.passwordForgot,
        data: {'email': email},
      );
      return ForgotPasswordResponse.fromJson(json);
    } on NetworkException {
      rethrow;
    }
  }
}
