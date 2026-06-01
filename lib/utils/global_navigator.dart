import 'package:flutter/material.dart';

class GlobalNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> push<T>(Widget page) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
