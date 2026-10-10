import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'iam/presentation/sign_in_page.dart';

void main() {
  runApp(const IceTrackApp());
}

class IceTrackApp extends StatelessWidget {
  const IceTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IceTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SignInPage(),
    );
  }
}
