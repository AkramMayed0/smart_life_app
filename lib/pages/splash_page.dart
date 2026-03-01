import 'package:easy_splash_screen/easy_splash_screen.dart';
import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EasySplashScreen(
      logo: Image.network(
        'https://play-lh.googleusercontent.com/M29pkEabzdIihXxY6d9N1i-hX1ZO8Trt2UTni65CG9NcOZaCTwEusFO3PEBWM4cWdcs',
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      showLoader: true,
      loadingText: Text('Loading...', style: theme.textTheme.bodyMedium),
      navigator: const AuthGate(),
      durationInSeconds: 3,
    );
  }
}
