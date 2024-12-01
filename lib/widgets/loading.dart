import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class Loading {
  static late BuildContext dialogContext;

  static Future<void> show(String text) async {
    var a = await showDialog(
        barrierDismissible: false,
        useSafeArea: true,
        context: prefs.context(),
        builder: (context) {
          dialogContext = context;
          return SimpleDialog(
            title: Text(text),
            contentPadding: EdgeInsets.fromLTRB(30, 5, 30, 5),
            children: [Center(child: LinearProgressIndicator())],
          );
        });
    return a;
  }
}
