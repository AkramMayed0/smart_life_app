import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 37, 146, 255),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 37, 200, 255),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }
}
