
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension Prefs on SharedPreferences {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const debug_res = 143;

  String string(String key) {
    return getString(key) ?? '';
  }

  String appTitle() {
    return string('title');
  }

  BuildContext context() {
    return navigatorKey.currentContext!;
  }

  String dateStr(DateTime d) {
    return DateFormat('yyyy-MM-dd').format(d);
  }
}

late SharedPreferences prefs;