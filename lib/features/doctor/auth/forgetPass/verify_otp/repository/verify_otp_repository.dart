import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/password_api_helper.dart';

import '../data/verify_otp_response.dart';

class VerifyOtpRepository {
  Future<VerifyOtpResponse> verify({
    required String email,
    required String otpCode,
  }) async {
    final json = await PasswordApiHelper.post(
      ApiConstants.passwordVerifyOtp,
      data: {'email': email, 'otp_code': otpCode},
    );
    return VerifyOtpResponse.fromJson(json);
  }
}
