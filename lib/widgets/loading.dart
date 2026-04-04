import 'dart:async';

import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class Loading {
  static late BuildContext dialogContext;
  static Completer<void>? _displayedCompleter;

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

  /// Показать индикатор и дождаться первого кадра (чтобы [dialogContext] был валиден).
  /// В отличие от [show], Future здесь не ждёт закрытия диалога.
  static Future<void> showUntilDisplayed(String text) async {
    _displayedCompleter = Completer<void>();
    showDialog<void>(
      barrierDismissible: false,
      useSafeArea: true,
      context: prefs.context(),
      builder: (context) {
        dialogContext = context;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!(_displayedCompleter?.isCompleted ?? true)) {
            _displayedCompleter!.complete();
          }
        });
        return SimpleDialog(
          title: Text(text),
          contentPadding: EdgeInsets.fromLTRB(30, 5, 30, 5),
          children: [Center(child: LinearProgressIndicator())],
        );
      },
    );
    await _displayedCompleter!.future;
  }

  /// Закрыть один показанный лоадер. Не вызывать в цикле по [canPop] у того же навигатора —
  /// иначе снимутся все маршруты вплоть до корня.
  static void dismiss() {
    try {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    } catch (_) {}
  }
}
