import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_images.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../../superAdmin/login/widgets/admin_login_dialog.dart';
import '../../home/screens/main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Bounce(
                onLongPress: (_) => showAdminLoginDialog(context),
                child: Image.asset(
                  AppImages.logoWithoutBack,
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 80),
              AppTextField(
                hintText: AppTexts.userNameHint,
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 20),
              AppTextField(
                hintText: AppTexts.passwordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 40),

              AppButton(
                label: AppTexts.login,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
