
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension Prefs on SharedPreferences {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String string(String key) {
    return getString(key) ?? '';
  }

  String appTitle() {
    return string('title');
  }

  BuildContext context() {
    return navigatorKey.currentContext!;
  }
}

late SharedPreferences prefs;