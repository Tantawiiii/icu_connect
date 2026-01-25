import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/features/home/screens/main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/app_logo_without_back.png",width: 160, height: 160,),
              const SizedBox(height: 60),
              TextField(
                decoration: const InputDecoration(
                  hintText: AppTexts.userNameHint,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: AppTexts.passwordHint,
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                child: const Text(AppTexts.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
