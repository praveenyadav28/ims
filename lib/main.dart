import 'package:flutter/material.dart';
import 'package:ims/ui/onboarding/splash_screen.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  Preference.preferences = await SharedPreferences.getInstance();
  Preference.getBool(PrefKeys.userstatus);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Sizes.init(context);
    return MaterialApp(
      title: 'IMS',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}
