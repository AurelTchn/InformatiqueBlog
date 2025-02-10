import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ThemeProvider with ChangeNotifier {
  bool isDark = false;

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme {
    return isDark ? darkTheme : lightTheme;
  }

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 15, 70, 119),
          foregroundColor: Colors.white,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          labelMedium: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      );
}

/* class ConnectivityProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _checkInternetConnection();
  }

  void _checkInternetConnection() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }
} */

class ConnectivityProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _checkInternetConnection();
  }

  void _checkInternetConnection() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      await _updateConnectionStatus(results);
    });
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool hasInternet = await _hasInternetAccess();
    bool newState = results.isEmpty || results.contains(ConnectivityResult.none) || !hasInternet;

    if (_isOffline != newState) {
      _isOffline = newState;
      notifyListeners();
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (e) {
      return false; // Pas d'accès à Internet
    }
  }
}