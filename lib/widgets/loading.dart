import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class Loading {
  static late BuildContext dialogContext;

  static Future<void> show() async {
    var a = await showDialog(
        barrierDismissible: false,
        useSafeArea: true,
        context: Prefs.navigatorKey.currentContext!,
        builder: (context) {
          dialogContext = context;
          return const SimpleDialog(
            title: Text('Loading...'),
            contentPadding: EdgeInsets.fromLTRB(30, 5, 30, 5),
            children: [Center(child: LinearProgressIndicator())],
          );
        });
    return a;
  }
}
